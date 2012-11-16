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

      # provides a Proc to the transform method, for use e.g. with Mongo documents
      # If you want to cache a transformer for reuse, you can cache just this Proc
      def to_proc
        method(:transform).to_proc
      end
    end
  end
end
