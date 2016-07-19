require 'syslog/logger'
require 'fileutils'

module Sortinghat
  class Banquet

    include Sortinghat::Magic

    # Creation method
    def initialize(options = {})

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

    # Main method of Sortinghat
    def sort!

      # Check that we have write premissions
      checkpermissions('/etc/hosts')

      # Best thing to avoid run conditions are to wait
      sleep rand(10)

      # Find out who is who, instances alive
      # If discover() returns an Array full of nil(s), alive will become an empty Array
      alive = cleanup(@aws.discover())

      # Given the alive instances, find our prefix
      # If alive an empty array, selection will return the number '1'
      @prefix = ensurezero(selection(alive))

      # Put together hostname/fqdn
      construction()

      # Set the Name tag on this instance
      @aws.settag!(@hostname)

      # Find out who is who, instances alive
      # If discover() returns an Array full of nil(s), alive will become an empty Array
      alive = cleanup(@aws.discover())

      # Only enter recursion if the uniq() length of the alive array does not equal the actual length
      # On AutoScalingGroup initalization, the cleanup() should ensure the alive array is empty not nil so uniq() works
      unless alive.uniq.length == alive.length
        # There are duplicates, remove tag, wait, restart
        @aws.removetag!()
        sleep rand(10)
        start!()
      end

      # Register in DNS
      @aws.setroute53(@options[:zone], @fqdn)

      # Set the localhost hostname
      setlocal()

      # Set /etc/hosts
      sethostsfile()

      # Throw the hostname in /etc/sysconfig/httpd (if exists)
      givetohttpd()

      # All done
      setsentinel!()
    end
  end
end
