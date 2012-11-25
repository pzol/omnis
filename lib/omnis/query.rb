require 'active_support/core_ext/hash'

module Omnis
  module Query

    class Param
      attr_reader :name, :operator, :opts
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

      # extracts the value for a param, using the extractor lamba or the default value
      def extract(params)
        value = @extractor.(params) if params.keys.include? name    # only run extractor if the param was in the request (params)
        value ||= default                                           # if there is a default, apply it
        return value if value.is_a? Omnis::Operators::NullOperator
        return @operator.new(@name, value, @opts) unless value.nil?
      end

      def default
        expr = @opts[:default]
        return expr.call if expr.is_a? Proc
        return expr
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
        self.class.params.fetch(name).extract(@input_params)
      end

      def extract
        self.class.params.map { |k,v| v.extract(@input_params) }.compact
      end

      # a list of keys that have been requested
      def keys
        extract.map(&:key)
      end
    end
  end
end
