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

      def property(name, expr, opts={})
        xtr = Proc === expr ? expr : @extractor.extractor(expr)
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
        value = property.extract(source) || property.default
        if property.format
          property.format.call(value)
        else
          value
        end
      end

      def transform(source)
        Hash[self.class.properties.map do |k, v| [k, __extract(v, source)] end]
      end
    end
  end
end
