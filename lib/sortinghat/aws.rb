require 'aws-sdk'
require 'net/http'
require 'uri'

module Sortinghat
  class AWS
    def initialize( region = 'us-east-1' )
      @region = region
      @client = Aws::EC2::Client.new(region: @region)
    end

    # Method to discover all the alive auto-scaling instances
    # Returns array of the Name tag values of the instances
    def discover()
      this = Array.new
      autoscale = Aws::AutoScaling::Client.new( region: @region )
      resp = autoscale.describe_auto_scaling_instances()
      resp.auto_scaling_instances.each do |instance|
	this << idtoname(instance.instance_id)
      end
      return this
    end

    def settag!(hostname)
      resource = Aws::EC2::Resource.new(client: @client)
      resource.instance(grabinstanceid()).create_tags({
        tags: [
          { 
            key: 'Name',
            value: hostname,
          },
	]
      })
    end

    def removetag!()
      resource = Aws::EC2::Resource.new(client: @client)
      resource.instance(grabinstanceid()).create_tags({
        tags: [
          {
            key: 'Name',
            value: "sortinghat-#{rand(100)}",
          },
        ]
      })
    end

    def setroute53(zone, hostname, fqdn)

    end

    private

    def idtoname(instance_id)
      resource = Aws::EC2::Resource.new(client: @client)
      resource.instance(instance_id).tags.each do |tag|
        if tag.key == 'Name'
          return tag.value
        end
      end
    end

    def grabinstanceid()
      return Net::HTTP.get_response(URI.parse("http://169.254.169.254/latest/meta-data/instance-id")).body
    end
  end
end
