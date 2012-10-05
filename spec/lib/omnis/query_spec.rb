require 'spec_helper'
require 'omnis/operators'
require 'omnis/query'
require 'active_support/core_ext/hash'

describe Omnis::Query::Param do
  it "supports equality" do
    Omnis::Query::Param.new(:param, Omnis::Operators::Matches).should == Omnis::Query::Param.new(:param, Omnis::Operators::Matches)
    Omnis::Query::Param.new(:param, Omnis::Operators::Between).should_not == Omnis::Query::Param.new(:param, Omnis::Operators::Matches)
  end
end

describe Omnis::Query do
  class TestBookingParams
    include Omnis::Query

    def self.parse_date(params, name)
      param = params[name]
      return nil if param.nil?
      time = Time.parse(param)
      Between.new(name, time.getlocal.beginning_of_day..time.getlocal.end_of_day)
    end

    param :ref_anixe, Matches
    param :passenger, Equals
    param(:date, Between) {|params| self.parse_date(params, :date) }
  end

  it "allows to fetch a single param" do
    t = TestBookingParams.new({"ref_anixe" => "1abc"})
    t.fetch(:ref_anixe).should == Omnis::Operators::Matches.new(:ref_anixe, "1abc")
  end

  it "allows to fetch all at once" do
    t = TestBookingParams.new({"ref_anixe" => "1abc"})
    t.params.should == [Omnis::Operators::Matches.new(:ref_anixe, "1abc")]
  end

  it "allows using blocks for extracing params" do
    t = TestBookingParams.new({"date" => "2012-10-02"})
    value = t.fetch(:date).value
    value.begin.should be_eql Time.local(2012, 10, 02, 0, 0, 0)
    value.end.to_i.should == Time.local(2012, 10, 02, 23, 59, 59).to_i
  end
end
