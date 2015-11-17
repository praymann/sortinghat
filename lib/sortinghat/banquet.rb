require 'syslog/logger'
require 'fileutils'

module Sortinghat
  class Banquet

    # Creation method
    def initialize(options = {})
      # Check that we have write premissions
      checkpermissions()

      # Create a syslog for us to use as an instance variable
      @log = Syslog::Logger.new 'sortinghat'

      # Append a trailing dot to the zone, if there isn't one
      if options[:zone][-1, 1] != '.'
        options[:zone] << '.'
      end

      # Save the options as instance variable
      @options = options

      # Create an instance varible to contain our AWS calls
      @aws = Sortinghat::AWS.new(@options[:region])
    end

    # Method to figure out if we've been here before
    def dejavu?
      # Check for sentinel file
      if File.exists?('/etc/.sorted')
        # We found it, log error and exit successfully
        @log.error('Found /etc/.sorted, refusing to sort.')
        abort('Found /etc/.sorted, refusing to sort.')
      end
    end

    # Main method of Sortinghat
    def start!

      # Find out who is who, instances alive
      alive = cleanup(@aws.discover())

      # Given the alive instances, find our prefix
      @prefix = ensurezero(selection(alive))

      # Put together hostname/fqdn
      construction()

      @aws.settag!(@hostname)

      # Find out who is who, instances alive
      alive = cleanup(@aws.discover())

      unless alive.uniq.length == alive.length
        # There are duplicates, remove tag, wait, restart
        @aws.removetag!()
        sleep rand(10)
        start!()
      end 

      @aws.setroute53(@options[:zone], @hostname, @fqdn)

      finish!()
    end

    # Last method of Sortinghat
    def finish!
      # Create our sentinel file
      FileUtils.touch('/etc/.sorted')
    end

    private

    def checkpermissions()
      unless File.stat('/etc/hosts').writable?
        # We found it, log error and exit successfully
        @log.error('Can not write to /etc, missing required permissions.')
        abort('Can not write to /etc, are you root?')
      end
    end

    def cleanup(array)
      array.select! { |name| name.include?(@options[:env]) and name.include?(@options[:client]) and name.include?(@options[:type]) }
    end

    def selection(array)
      # Array to store the numbers already taken 
      taken = Array.new
      
      # Filter the incoming array, find the numbers and store them in the taken Array
      array.each { |string| taken << string.scan(/\d./).join('').sub(/^0+/, '').to_i }
      
      # We have two digits, define our range of numbers
      limits = (1..99).to_a

      # Return the first value once we find what isn't taken in our range of numbers 
      (limits - taken)[0]
    end

    def ensurezero(prefix)
      if prefix < 10
        prefix.to_s.rjust(2, "0")
      end
    end

    def construction()
      @hostname = "#{@options[:client]}-#{@options[:env]}-#{@options[:type]}#{@prefix.to_s}-#{@options[:region]}"
      @fqdn = "#{@options[:client]}-#{@options[:env]}-#{@options[:type]}#{@prefix.to_s}-#{@options[:region]}.#{@options[:zone]}"
    end
  end
end
