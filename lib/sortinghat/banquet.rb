require 'syslog/logger'
require 'fileutils'

module Sortinghat
  class Banquet

    def self.assign_house(options = {})
      this = new(options)
      this.dejavu?
      this.start!
    end

    # Creation method
    def initialize(options = {})
      # Check that we have write premissions
      checkpermissions

      # Create a syslog for us to use as an instance variable
      @log = Syslog::Logger.new 'sortinghat'

      # Append a trailing dot to the zone, if there isn't one
      options[:zone] << '.' if options[:zone][-1, 1] != '.'

      # Save the options as instance variable
      @options = options

      # Create an instance varible to contain our AWS calls
      @aws = Sortinghat::AWS.new(@options[:region])
    end

    # Method to figure out if we've been here before
    def dejavu?
      # Check for sentinel file
      if File.exist?('/etc/.sorted')
        # We found it, log error and exit successfully
        @log.info('Found /etc/.sorted, refusing to sort.')
        exit 0
      end
    end

    # Main method of Sortinghat
    def start!
      construct_hostname

      # Set the Name tag on this instance
      @aws.settag!(@hostname)

      # Register in DNS
      @aws.setroute53(@options[:zone], @fqdn)

      # Set the localhost hostname
      setlocal

      # Set /etc/hosts
      sethostsfile

      # Throw the hostname in /etc/sysconfig/httpd (if exists)
      givetohttpd

      # All done
      finish!
    end

    # Last method of Sortinghat
    def finish!
      # Create our sentinel file
      FileUtils.touch('/etc/.sorted')
    end

    private

    # Method to check that we have write permissions to /etc/*
    def checkpermissions
      unless File.stat('/etc/hosts').writable?
        # We found it, log error and exit successfully
        @log.error('Can not write to /etc, missing required permissions.')
        abort('Can not write to /etc, are you root?')
      end
    end

    # Method to cleanup the array returned by aws.discover()
    # Remove nil values basically
    def cleanup(array)
      clean = array.reject(&:nil?)
      return [] if clean.empty?
      clean
    end

    # Cconsume the alive array and return array of available suffix
    def selection(array)
      array = cleanup(array)

      # If array is empty, just return 01
      return [1] if array.empty?

      # Filter the incoming array, find the numbers and store them in the taken Array
      taken = array.map { |str| str[/^.*\D(\d{2,}).*/, 1].sub(/^0+/, '').to_i }

      # We have two digits, define our range of numbers
      limits = (1..99).to_a

      # Return the avilable values once we find what isn't taken in our range of numbers
      limits - taken
    end

    def construct_hostname
      # Get array of hostnames in our scale group
      scalegroup_hosts = @aws.discover

      # determine the next available suffix
      selection(scalegroup_hosts).find(method(:assignment_unclear)) do |candidate|
        @suffix = ensurezero(candidate)
        construction
        matches = @aws.search_hosts(@hostname)
        matches.empty?
      end
    end

    # Method to ensure our suffix always has a leading 0 if < 10
    def ensurezero(suffix)
      return suffix.to_s.rjust(2, '0') if suffix < 10
      suffix
    end

    # Method to construct our instance variables @hostname and @fqdn
    def construction
      @hostname = "#{@options[:client]}-#{@options[:env]}-#{@options[:type]}#{@suffix}-#{@options[:region]}"
      @fqdn = "#{@options[:client]}-#{@options[:env]}-#{@options[:type]}#{@suffix}-#{@options[:region]}.#{@options[:zone]}"
    end

    def assignment_unclear
      @suffix = "sh#{rand(100)}"
      contruction
    end

    # Method to set the local hostname on this instance
    def setlocal
      if system("hostnamectl set-hostname #{@fqdn}")
        @log.info("Set the localhost hostname to #{@fqdn}.")
      end
    end

    def sethostsfile
      # Store the ip address so we only make one metadata call here
      privateip = @aws.privateip()
      if File.readlines('/etc/hosts').grep(/#{@hostname}|#{privateip}/).empty?
        File.open('/etc/hosts', 'a') do |file|
          file.puts "#{privateip} \t #{@hostname} #{@fqdn}"
        end
        @log.info('Added hostname(s) to /etc/hosts.')
      else
        @log.warn('The hostname(s) were already in /etc/hosts.')
      end
    end

    def givetohttpd
      file = '/etc/sysconfig/httpd'
      return unless File.exist?(file)
      if File.readlines(file).grep(/HOSTNAME/).empty?
        @log.info("Found #{file}, appending HOSTNAME=#{@hostname}.")
        File.open(file, 'a') { |sysconfig| sysconfig.puts "HOSTNAME=#{@hostname}" }
      else
        @log.warn("Found HOSTNAME already in #{file}")
      end
    end
  end
end
