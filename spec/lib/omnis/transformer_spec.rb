require 'spec_helper'
require 'monadic'
require 'omnis/nested_hash_extractor'
require 'omnis/transformer'

describe Omnis::Transformer do
  class TestTransformer
    include Omnis::Transformer
    extractor Omnis::NestedHashExtractor.new

    property :ref,       "ref_anixe"
    property :date_from, ->source { extract(Maybe(source), "services.0.date_from").or(Time.at(0)).fetch }
    property :date_to,   "services.0.date_to",   :default => Time.at(0), :format => ->v { v.strftime("%Y-%m-%d") }
    property :agency,    "agency",               :default => "000000"
  end

  let(:doc) {
    { "ref_anixe" => "1abc",
      "contract" => "test",
      "agency"   => nil,
      "services" => [ { "date_from" => "2012-10-10"}]}
  }

  it "should do something" do
    t = TestTransformer.new
    t.transform(doc).should == { :ref => "1abc", :date_from => "2012-10-10", :date_to => "1970-01-01", :agency => "000000" }
  end
end