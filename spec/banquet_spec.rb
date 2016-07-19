require 'spec_helper'

describe Sortinghat::Banquet do
  before :each do
    @b = Sortinghat::Banquet.new({
      client: 'client',
      env: 'env',
      type: 'type',
      region: 'region',
      zone: 'zone'})
    @options = @b.instance_variable_get(:@options)
    @aws = @b.instance_variable_get(:@aws)
  end

  describe '#new' do
    context 'without region parameter' do
      it 'should raise' do
        expect{Sortinghat::Banquet.new({
              client: 'client',
              env: 'env',
              type: 'type',
              zone: 'zone'})}.to raise_error(Aws::Errors::MissingRegionError)
      end
    end

    context 'with no parameters' do
      it 'should raise' do
        expect{Sortinghat::Banquet.new()}.to raise_error(NoMethodError)
      end
    end

    context 'with all parameters' do
      it 'returns a Banquet object' do
        expect(@b).to be_an_instance_of Sortinghat::Banquet
      end

      it 'returns correct client' do
        expect(@options[:client]).to eql 'client'
      end

      it 'returns correct env' do
        expect(@options[:env]).to eql 'env'
      end

      it 'returns correct type' do
        expect(@options[:type]).to eql 'type'
      end

      it 'returns correct region' do
        expect(@options[:region]).to eql 'region'
      end

      context 'returns correct zone' do
        it 'adds trailing period when is none' do
          # We expect it to append a '.'
          expect(@options[:zone]).to eql 'zone.'
        end

        it 'does not add trailing period when there is' do
          b = Sortinghat::Banquet.new({
            client: 'client',
            env: 'env',
            type: 'type',
            region: 'region',
            zone: 'zone.'})
          options = b.instance_variable_get(:@options)
          expect(@options[:zone]).to eql 'zone.'
        end
      end
    end

    context 'AWS client' do
      it 'should not be nil' do
        expect(@aws).not_to eql nil
      end
    end
  end

  describe '#sort!' do
  end

end
