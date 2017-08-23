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
  end

  describe '#new' do
    context 'should raise' do
      it 'without a region' do
        expect{Sortinghat::Banquet.new({
              client: 'client',
              env: 'env',
              type: 'type',
              zone: 'zone'})}.to raise_error(Aws::Errors::MissingRegionError)
      end
    end

    it 'takes options hash and returns a Banquet object' do
      expect(@b).to be_an_instance_of Sortinghat::Banquet
    end

    context 'options hash' do
      it 'sets client key' do
        expect(@options[:client]).to eql 'client'
      end

      it 'sets env key' do
        expect(@options[:env]).to eql 'env'
      end

      it 'sets type key' do
        expect(@options[:type]).to eql 'type'
      end

      it 'sets region key' do
        expect(@options[:region]).to eql 'region'
      end

      context 'sets zone key' do
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
  end
end
