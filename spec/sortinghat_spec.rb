require 'spec_helper'

describe Sortinghat do
  it 'has a version number' do
    expect(Sortinghat::VERSION).not_to be nil
  end
end

Aws.config[:s3] = {
  stub_responses: {
    list_buckets: { buckets:[{name:'aws-sdk'}]}
  }
}

Aws::S3::Client.new.list_buckets.buckets.map(&:name)
#=> ["aws-sdk"]