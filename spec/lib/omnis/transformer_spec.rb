require 'spec_helper'
require 'ostruct'
require 'monadic'
require 'omnis/nested_hash_extractor'
require 'omnis/transformer'

describe Omnis::Transformer do
  class TestTransformer
    include Omnis::Transformer
    extractor Omnis::NestedHashExtractor.new

    property :ref,       "ref_anixe"
    property(:date_from) {|source| Maybe(extract(source, "services.0.date_from")).or(Time.at(0)).fetch }
    property :date_to,   "services.0.date_to",   :default => Time.at(0), :format => ->v { v.strftime("%Y-%m-%d") }
    property :agency,    "agency",               :default => "000000"
  end

  let(:doc) {
    { "ref_anixe" => "1abc",
      "contract" => "test",
      "agency"   => nil,
      "services" => [ { "date_from" => "2012-10-10"}]}
  }

  it "should read values from the doc" do
    t = TestTransformer.new
    t.transform(doc).should == { :ref => "1abc", :date_from => "2012-10-10", :date_to => "1970-01-01", :agency => "000000" }
  end

  it "should support blocks in properties, without a defined extractor" do
    class TestTransformerWithBlock
      include Omnis::Transformer
      property(:ref) {|src| Maybe(src)["ref_anixe"].fetch }
    end

    t = TestTransformerWithBlock.new
    t.transform(doc).should == { :ref => "1abc" }
  end

  it "should raise an ArgumentError if no block and no expression provided" do
    expect {
      class TestTransformerInvalid
        include Omnis::Transformer
        property :ref
      end
    }.to raise_error ArgumentError
  end

  it "uses a #to_object method if provided to convert the resulting Hash into an Object" do
    class TestTransformerWithToObject
      include Omnis::Transformer
      property(:ref) {|src| src["ref_anixe"]}
      def to_object(hash)
        OpenStruct.new(hash)
      end
    end
    t = TestTransformerWithToObject.new
    t.transform(doc).should == OpenStruct.new(ref: "1abc")
  end

  it 'provides a tranformer lambda' do
    class TestXformer
      include Omnis::Transformer
      property(:ref) {|src| src['ref_anixe']}
    end
    t = TestXformer.new
    xformer = t.to_proc
    xformer.should be_a Proc
    xformer.({"ref_anixe" => "2two"}).should == {:ref => "2two"}
  end
end
