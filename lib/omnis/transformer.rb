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

      # If an expr is provided it will be passed to the configured extractor,
      # otherwise a block should be given. As last resort, it embeds a lambda to
      # look for a class method with the name of the param (at runtime)
      def property(name, expr=nil, opts={}, &block)
        xtr = case
              when String === expr    ; @extractor.extractor(expr)
              when block_given?       ; block
              else
                ->(source) { self.send(name, source) }
              end

        Omnis::Transformer::Property.new(name, expr, opts, xtr).tap do |prop|
          properties[prop.name] = prop
        end
      end

      def to_value(&block)
        @to_value = block
      end

      def apply_to_value(value)
        @to_value ? @to_value.(value) : value
      end

      def extractor(obj)
          @extractor = obj
      end

      def extract(source, expr)
        @extractor.extractor(expr).call(source)
      end
    end

    module InstanceMethods
      def columns
        self.class.properties.keys
      end

      def property_value(property, source)
        raw_value = property.extract(source)
        raw_value = property.default if property.default && (raw_value == Nothing || raw_value.nil?)
        applied_value = self.class.apply_to_value(raw_value)
        property.format ? property.format.call(applied_value) : applied_value
      end

      def transform(source)
        result = Hash[self.class.properties.map do |k, v| [k, property_value(v, source)] end]
        respond_to?(:to_object) ? to_object(result) : result
      end

      # provides a Proc to the transform method, for use e.g. with Mongo documents
      # If you want to cache a transformer for reuse, you can cache just this Proc
      def to_proc
        method(:transform).to_proc
      end
    end
  end
end
