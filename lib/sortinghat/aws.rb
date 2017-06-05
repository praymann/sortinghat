require 'aws-sdk'
require 'net/http'
require 'uri'
require 'date'

module Sortinghat
  class AWS
    def initialize(region = 'us-east-1')
      # Be using this lots, make it an instance variable
      @region = region

      # Set a generic client for use
      @ec2_client = Aws::EC2::Client.new(region: @region)
      @autoscale_client = Aws::AutoScaling::Client.new(region: @region)

      # Create a syslog for us to use as an instance variable
      @log = Syslog::Logger.new 'sortinghat'
    end

    # Method to discover what auto-scaling group the current instance is in, then the instances in that group
    # Returns array of the Name tag values of the instances
    def discover
      # Use the client to grab all instances in this auto-scaling group
      all = @autoscale_client.describe_auto_scaling_groups(
        auto_scaling_group_names: [find_own_autoscale_name],
        max_records: 1
      )
      @log.info('Grabbed the instances of our AutoScaling group via aws-sdk')

      # Grab their hostname(s)
      names = all.auto_scaling_groups[0].instances.map { |instance| idtoname(instance.instance_id) }
      @log.info("Returning instances '#{names.join("','")}'")

      # Return the ids
      names
    end

    # Method to search for instances matching a hostname
    # Returns array of instances
    def search_hosts(hostname)
      resp = @client.describe_instances(filters: [{ name: 'tag:Name', value: [hostname] }])
      return resp.reservations unless resp.reservations.empty?
      []
    end

    # Method to set the Name tag on the current instance
    # Returns nothing
    def settag!(hostname)
      # Use the instance varible client to create a new Resource
      resource = Aws::EC2::Resource.new(client: @client)

      # Use the resource, to find current instance, and set the Name tag
      resource.instance(grabinstanceid)
              .create_tags(tags: [{ key: 'Name', value: hostname }])
      @log.info("Set Name tag to #{hostname} via aws-sdk")
    end

    # Method to remove the Name tag, and set a temporary one
    # Returns nothing
    def removetag!
      # Use the instance varible client to create a new Resource
      resource = Aws::EC2::Resource.new(client: @client)

      # Use the resource, to find current instance, and set the Name tag
      resource.instance(grabinstanceid)
              .create_tags(
                tags: [{ key: 'Name', value: "sortinghat-#{rand(100)}" }]
              )
      @log.info("Set Name tag to temporary #{hostname} via aws-sdk")
    end

    # Method to set the A record in Route53
    # Returns nothing
    def setroute53(zone, fqdn)
      # Create a new client, and use it to update/insert our A record
      Aws::Route53::Client.new(region: @region).change_resource_record_sets(
        hosted_zone_id: zonetoid(zone),
        change_batch: {
          comment: "Sorting Hat #{Date.today}",
          changes: [
            {
              action: 'UPSERT',
              resource_record_set: {
                name: fqdn,
                type: 'A',
                ttl: '30',
                resource_records: [{ value: grabinstanceprivateip }]
              }
            }
          ]
        }
      )
      @log.info("Issued UPSERT to Route53 for #{fqdn}")
    end

    def privateip
      grabinstanceprivateip
    end

    private

    def idtoname(instance_id)
      resource = Aws::EC2::Resource.new(client: @client)
      name = resource.instance(instance_id).tags.find { |tag| tag.key == 'Name' }
      return name.value unless name.nil?
    end

    def zonetoid(hostedzone)
      resp = Aws::Route53::Client.new(region: @region).list_hosted_zones
      resp.hosted_zones.each do |zone|
        return zone.id if zone.name == hostedzone
      end
    end

    def grabinstanceid
      Net::HTTP.get_response(URI.parse('http://169.254.169.254/latest/meta-data/instance-id')).body
    end

    def grabinstanceprivateip
      Net::HTTP.get_response(URI.parse('http://169.254.169.254/latest/meta-data/local-ipv4')).body
    end

    def find_own_autoscale_name
      # Use the client to describe this instances autoscale
      current_as = @autoscale_client.describe_auto_scaling_instances(
        instance_ids: [grabinstanceid],
        max_records: 1
      )
      @log.info('Grabbed current AutoScaling instance via aws-sdk')

      # Return current autoscale name
      current_as.auto_scaling_instances[0].auto_scaling_group_name
    end
  end
end
