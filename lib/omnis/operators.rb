module Omnis
  module Operators
    class NullOperator
      attr_reader :key, :value, :opts
      def initialize(key, value, opts={})
        @key, @value, @opts = key, value, opts
      end

      def ==(other)
        return false unless other.is_a? self.class
        return false unless @key == other.key
        @value == other.value
      end

      def to_s
        klas = self.class.to_s.downcase.split('::')[-1]
        "#{@key.to_s} #{klas} #{@value}"
      end
    end

    Any = NullOperator

    class Matches < NullOperator
      def mongo_value
        /#{value}/i
      end
    end

    class Equals < NullOperator
      def mongo_value
        value
      end
    end

    class Gte < NullOperator
    end

    class Between < NullOperator
      def mongo_value
        { :'$gte' => value.begin, :'$lt' => value.end }
      end
    end

    class BeginsWith < NullOperator
      def mongo_value
        /^#{value}/i
      end
    end
  end
end
