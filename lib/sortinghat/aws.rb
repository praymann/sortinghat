require 'aws-sdk'
require 'net/http'
require 'uri'
require 'date'

module Sortinghat
  class AWS
    def initialize( region = 'us-east-1' )
      # Be using this lots, make it an instance variable
      @region = region

      # Set a generic client for use
      @client = Aws::EC2::Client.new(region: @region)

      # Create a syslog for us to use as an instance variable
      @log = Syslog::Logger.new 'sortinghat'
    end

    # Method to discover all the alive auto-scaling instances
    # Returns array of the Name tag values of the instances
    def discover()
      # Temporay array for use
      ids = Array.new
      
      # Start a new client
      autoscale = Aws::AutoScaling::Client.new( region: @region )

      # Use the client to grab all autoscaling instances
      resp = autoscale.describe_auto_scaling_instances()
      @log.info("Grabbed all AutoScaling instances via aws-sdk")

      # Grab their instanceId(s)
      resp.auto_scaling_instances.each do |instance|
	ids << idtoname(instance.instance_id)
      end
      
      # Return the ids
      ids
    end

    # Method to set the Name tag on the current instance
    # Returns nothing
    def settag!(hostname)
      # Use the instance varible client to create a new Resource
      resource = Aws::EC2::Resource.new(client: @client)

      # Use the resource, to find current instance, and set the Name tag
      resource.instance(grabinstanceid()).create_tags({
        tags: [
          { 
            key: 'Name',
            value: hostname,
          },
	]
      })
      @log.info("Set Name tag to #{hostname} via aws-sdk")
    end

    # Method to remove the Name tag, and set a temporary one
    # Returns nothing
    def removetag!()
      # Use the instance varible client to create a new Resource
      resource = Aws::EC2::Resource.new(client: @client)

      # Use the resource, to find current instance, and set the Name tag
      resource.instance(grabinstanceid()).create_tags({
        tags: [
          {
            key: 'Name',
            value: "sortinghat-#{rand(100)}",
          },
        ]
      })
      @log.info("Set Name tag to temporary #{hostname} via aws-sdk")
    end

    # Method to set the A record in Route53
    # Returns nothing
    def setroute53(zone, fqdn)
      # Create a new client, and use it to update/insert our A record
      Aws::Route53::Client.new(region: @region).change_resource_record_sets({
        hosted_zone_id: zonetoid(zone),
        change_batch: {
          comment: "Sorting Hat #{Date.today.to_s}",
          changes: [
            {
              action: 'UPSERT',
              resource_record_set: {
                name: fqdn,
                type: 'A',
                ttl: '30',
                resource_records: [
                  {
                    value: grabinstanceprivateip()
                  },
                ],
              },
            },
          ],
        },
      })  
      @log.info("Issued UPSERT to Route53 for #{fqdn}")
    end

    def privateip()
      return grabinstanceprivateip()
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

    def zonetoid(hostedzone)
      resp = Aws::Route53::Client.new(region: @region).list_hosted_zones()
      resp.hosted_zones.each do |zone|
        if zone.name == hostedzone
          return zone.id
        end
      end
    end

    def grabinstanceid()
      return Net::HTTP.get_response(URI.parse("http://169.254.169.254/latest/meta-data/instance-id")).body
    end

    def grabinstanceprivateip()
      return Net::HTTP.get_response(URI.parse("http://169.254.169.254/latest/meta-data/local-ipv4")).body
    end
  end
end
