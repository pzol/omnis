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
        value ||= default_value                                     # if there is a default, apply it
        return value if extracted_result_is_an_operator? value
        return @operator.new(@name, value, @opts) unless value.nil?
      end

      def default_value
        expr = @opts[:default]
        return expr.call if expr.is_a? Proc
        return expr
      end

      private
      def extracted_result_is_an_operator?(value)
        value.is_a? Omnis::Operators::NullOperator
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

      # extracts operators from params
      # add the name of the param to each extracted operators
      def extract
        self.class.params.map do |k,v|
          v.extract(@input_params).tap do |operator|
            operator.opts[:param_name] = k unless operator.nil?
          end
        end.compact
      end
    end
  end
end
