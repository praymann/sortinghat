# Sortinghat

Sortinghat is a unqiue Ruby gem that allows AWS AutoScaling instances to name themselves.

We all understand that naming your cattle is bad, they shouldn't be pets.. but hostnames are handy and readable, and [insert reason].

When the Sorting Hat is given specific arguments, it can find the gaps in current prefixes or +1 from the last current prefix and name the instance accordingly; along with updating Route53.

It follows a specific pattern for hostnames/fqdn:

```
[client]-[environment]-[type][prefix].[domain].com.
```
For example:

```
nike-prod-nginx09.prod-nike.com
```

## Installation:

Install however you please to your AMI(s) with:

    $ gem install sortinghat

## Requirements:

The gem itself was developed under Ruby 2.0.0 to work with CentOS 7.

It requires the following gems:
* aws-sdk 2.1.2
* pure_json

During actually usage, the gem requires that the instance have the following IAM actions allowed via policy:
* autoscaling:DescribeAutoScalingInstances
* autoscaling:DescribeAutoScalingGroups
* ec2:DescribeInstances
* ec2:CreateTags
* route53:ListHostedZones
* route53:ChangeResourceRecordSets

## Usage:

Note: The Sorting Hat requires root privileges to write to files under /etc/.

Have cloud-init, cfn-init, or [x/y/z], issue the following command:

    $ sortinghat -c [client] -e [environment] -t [type] -r [region] -z [domain]

Note: [domain] should be in the format of [domain].com, just like the AWS Console reports for the HostedZone. No need to add the trailing dot, it will be added should you forget.

The Sorting Hat will log to syslog for information.

The Sorting Hat may be re-run, provided you remove the empty file located at '/etc/.sorted'.

## Development

Need to develop on an EC2 instance with metadata available or spoof it somehow.

Clone:

    $ git clone https://github.com/praymann/sortinghat

Execute:

    $ bundle install

Run:

    $ bundle exec bin/sortinghat -h


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/praymann/sortinghat.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

