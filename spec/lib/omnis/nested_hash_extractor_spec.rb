require 'spec_helper'
require 'omnis/nested_hash_extractor'

describe Omnis::NestedHashExtractor do
  let(:xtr) { Omnis::NestedHashExtractor.new }
  let(:doc) {
    { "ref_anixe" => "1abc",
      "contract" => "test",
      "agency"   => nil,
      "services" => [ { "date_from" => "2012-10-10"}]}
  }

  it "extracts values using a path" do
    xtr.extractor("ref_anixe").call(doc).should == "1abc"
    xtr.extractor("services.0.date_from").call(doc).should == "2012-10-10"
    xtr.extractor("agency").call(doc).should be_nil
  end

  it "returns Nothing if an expression points to a non-existant key" do
    xtr.extractor("ref_anixe").call({}).should == Nothing
  end

  it "returns Nothing for a nested path, if an exception would be raised" do
    xtr.extractor("a.b.c").call({}).should == Nothing
    xtr.extractor("a.(1]").call({}).should == Nothing
  end

  it "returns nil if the underlying value of a key is nil" do
    xtr.extractor("agency").call(doc).should be_nil
  end

end
