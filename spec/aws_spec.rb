require 'spec_helper'

describe Sortinghat::AWS do

end

Aws.config[:s3] = {
  stub_responses: {
    list_buckets: { buckets:[{name:'aws-sdk'}]}
  }
}

Aws::S3::Client.new.list_buckets.buckets.map(&:name)
#=> ["aws-sdk"]