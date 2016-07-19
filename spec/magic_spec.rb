require 'spec_helper'

describe Sortinghat::Magic do
  before :each do
    # Create a syslog for us to use as an instance variable
    @log = Syslog::Logger.new 'sortinghat'
  end

  describe '.cleanup' do
    context "with empty array" do
      it "should return empty array" do
        expect(Sortinghat::Magic.cleanup []).to eql []
      end
    end
    context "with array of nils" do
      it "should return empty array" do
        expect(Sortinghat::Magic.cleanup [nil,nil]).to eql []
      end
    end
    context "with array of 2 nils and 1 value" do
      it "should return array of size 1" do
        expect(Sortinghat::Magic.cleanup [nil,1,nil]).to eql [1]
      end
    end
    context "with array of 3 values" do
      it "should return array of size 3" do
        expect(Sortinghat::Magic.cleanup [1,2,3]).to eql [1,2,3]
      end
    end
  end

  describe '.selection' do
  end

  describe '.dejavu?' do
    context 'file does not exist' do
      it 'should return nil' do
        expect(Sortinghat::Magic.dejavu?('/sortinghat.rb')).to eql nil
      end
    end
    context 'file does exist' do
      it 'should exit' do
        expect{Sortinghat::Magic.dejavu?('Gemfile')}.raise_exception(SystemExit)
      end
      it 'exit value should be 0' do
        begin
          Sortinghat::Magic.dejavu?('Gemfile')
        rescue SystemExit=>e
          expect(e.status).to eql 0
        end
      end
    end
  end

  describe '.ensurezero' do
  end

  describe '.construction' do
  end
end