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
