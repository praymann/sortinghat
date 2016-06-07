module Sortinghat
  module Magic
    # include all methods defined as class methods too
    extend self

    # Method to figure out if we've been here before
    def dejavu?(file='/etc/.sorted')
      # Check for sentinel file
      if File.exists?(file)
        # We found it, log error and exit successfully
        @log.info('Found #{file}, refusing to sort.')
        exit 0
      end
    end

    # Method to check that we have write permissions to /etc/*
    def checkpermissions(file='/etc/hosts')
      unless File.stat(file).writable?
        # We found it, log error and exit successfully
        @log.error("Can not write to #{file}, missing required permissions.")
        abort("Can not write to #{file}, are you root?")
      end
    end

    # Method to cleanup the array returned by aws.discover()
    # Remove nil values basically
    def cleanup(array)
      clean = array.reject { |item| item.nil? }
      return [] if clean.empty?
      clean
    end

    # Method to consume the alive array and figure out what this instance's prefix should be
    def selection(array)
      # If array is empty, just return 01
      return 1 if array.empty?

      # Array to store the numbers already taken
      taken = Array.new

      # Filter the incoming array, find the numbers and store them in the taken Array
      array.each { |string| taken << string.scan(/\d./).join('').sub(/^0+/, '').to_i }

      # We have two digits, define our range of numbers
      limits = (1..99).to_a

      # Return the first value once we find what isn't taken in our range of numbers
      (limits - taken)[0]
    end

    # Method to ensure our prefix always has a leading 0 if < 10
    def ensurezero(prefix)
      prefix < 10 ? prefix.to_s.rjust(2, "0") : prefix
    end

    # Method to construct our instance variables @hostname and @fqdn
    def construction()
      @hostname = "#{@options[:client]}-#{@options[:env]}-#{@options[:type]}#{@prefix.to_s}-#{@options[:region]}"
      @fqdn = "#{@options[:client]}-#{@options[:env]}-#{@options[:type]}#{@prefix.to_s}-#{@options[:region]}.#{@options[:zone]}"
    end

    # Method to set the local hostname on this instance
    def setlocal()
      if system("hostnamectl set-hostname #{@fqdn}")
        @log.info("Set the localhost hostname to #{@fqdn}.")
      end
    end

    def sethostsfile()
      # Store the ip address so we only make one metadata call here
      privateip = @aws.privateip()
      if File.readlines('/etc/hosts').grep(/#{@hostname}|#{privateip}/).size < 1
        File.open('/etc/hosts', 'a') do |file|
          file.puts "#{privateip} \t #{@hostname} #{@fqdn}"
        end
        @log.info("Added hostname(s) to /etc/hosts.")
      else
        @log.warn("The hostname(s) were already in /etc/hosts.")
      end
    end

    def givetohttpd()
      file = '/etc/sysconfig/httpd'
      if File.exists?(file)
        if File.readlines(file).grep(/HOSTNAME/).size < 1
          @log.info("Found #{file}, appending HOSTNAME=#{@hostname}.")
          File.open(file, 'a') do |file|
            file.puts "HOSTNAME=#{@hostname}"
          end
        else
          @log.warn("Found HOSTNAME already in #{file}")
        end
      end
    end
  end
end