require 'spec_helper'
require 'omnis/operators'
require 'active_support/core_ext/hash'

module Omnis
  module Query

    class Param
      attr_reader :name, :operator
      def initialize(name, operator, opts={}, &extractor)
        # raise ArgumentError("operator must be a descendant of Omnis::Operators::NullOperator") unless operator.is_a? Omnis::Operators::NullOperator
        extractor ||= ->params { params[name] }
        @name, @operator, @opts, @extractor = name, operator, opts, extractor
      end

      def ==(other)
        return false unless other.is_a? self.class
        return false unless @name == other.name
        @operator == other.operator
      end

      def extract(params)
        value = @extractor.(params)
        return value if value.is_a? Omnis::Operators::NullOperator
        return @operator.new(@name, value) unless value.nil?
      end
    end

    def self.included(base)
      base.class_eval do
        extend ClassMethods
        include InstanceMethods
        include Omnis::Operators
      end
    end

    module ClassMethods
      def params
        @params ||= {}
      end

      def param(name, operator, opts={}, &block)
        Omnis::Query::Param.new(name, operator, opts, &block).tap do |param|
          params[param.name] = param
        end
      end
    end
    module InstanceMethods
      def initialize(input_params)
        @input_params = input_params.symbolize_keys
      end

      def fetch(name)
        self.class.instance_variable_get(:@params).fetch(name).extract(@input_params)
      end

      def params
        self.class.instance_variable_get(:@params).map { |k,v| v.extract(@input_params) }.compact
      end
    end
  end
end

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
    param(:date) {|params| self.parse_date(params, :date) }
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
