require 'spec_helper'

describe Sortinghat::Magic do
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
  end

  describe '.selection' do
  end

  describe '.ensurezero' do
  end

  describe '.construction' do
  end
end