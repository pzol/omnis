module Omnis
  module Transformer
    class Property
      attr_reader :name, :expr, :opts
      def initialize(name, expr, opts, extractor)
        @name, @expr, @opts, @extractor = name, expr, opts, extractor
      end

      def default
        opts[:default]
      end

      def format
        opts[:format]
      end

      def extract(source)
        @extractor.call(source)
      end
    end

    def self.included(base)
      base.class_eval do
        extend ClassMethods
        include InstanceMethods
      end
    end

    module ClassMethods
      def properties
        @properties ||= {}
      end

      # if an expr is provided it will be passed to the configured extractor,
      # otherwise a block is required
      def property(name, expr=nil, opts={}, &block)
        raise ArgumentError if (expr.nil? && block.nil?)

        xtr = case expr
              when String; @extractor.extractor(expr)
              when nil   ; block
              end

        Omnis::Transformer::Property.new(name, expr, opts, xtr).tap do |prop|
          properties[prop.name] = prop
        end
      end

      def extractor(obj)
          @extractor = obj
      end

      def extract(source, expr)
        @extractor.extractor(expr).call(source)
      end
    end

    module InstanceMethods
      def __extract(property, source)
        value = property_value(property, source)
        if property.format
          property.format.call(value)
        else
          value
        end
      end

      def property_value(property, source)
        value = property.extract(source)
        return property.default if property.default && (value == Nothing || value.nil?)
        return value
      end

      def transform(source)
        result = Hash[self.class.properties.map do |k, v| [k, __extract(v, source)] end]
        respond_to?(:to_object) ? to_object(result) : result
      end
    end
  end
end
