require 'ostruct'

module Omnis
  module MongoQuery
    include Omnis::Query
    def self.included(base)
      base.class_eval do
        include InstanceMethods
        extend ClassMethods
      end
    end

    module ClassMethods
      include Omnis::Query::ClassMethods

      attr_reader :page_param_name, :items_per_page
      def field_list
        @fields ||= []
      end
      def fields(list)
        field_list.concat(list)
      end

      def page(page_param_name, opts={})
        @page_param_name = page_param_name
        @items_per_page  = opts[:items_per_page] || 10
      end
    end

    module InstanceMethods
      include Omnis::Operators

      attr_reader :extracted_operators

      def to_mongo
        extracted_operators = extract
        OpenStruct.new({ :selector    => mongo_selector(extracted_operators),
                         :opts        => mongo_opts(extracted_operators),
                         :param_names => extracted_param_names(extracted_operators)})
      end

      private
      def page
        return 0 unless @input_params.has_key? page_param_name
        page_num = @input_params[page_param_name].to_i - 1
        return 0 if page_num < 0
        return page_num
      end

      def skip
        page * items_per_page
      end

      def page_param_name
        self.class.page_param_name || :page
      end

      def items_per_page
        self.class.items_per_page || 20
      end

      def mongo_operator(operator)
        case operator
        when Equals;      operator.value
        when Matches;     /#{operator.value}/i
        when BeginsWith;  /^#{operator.value}/i
        when Between;     { :'$gte' => operator.value.begin, :'$lt' => operator.value.end}
        end
      end

      def mongo_selector(extracted_operators)
        Hash[extracted_operators.map { |operator| [operator.key, mongo_operator(operator)] }]
      end

      def mongo_opts(extracted_operators)
        params_with_extra_fields = extracted_operators.collect(&:opts).select {|e| e.has_key? :field}
        extra_fields = params_with_extra_fields.map {|e| e[:field]}
        fields = self.class.field_list + extra_fields
        { :limit => items_per_page, :skip => skip, :fields => fields }
      end

      def extracted_param_names(extracted_operators)
        extracted_operators.map {|e| e.opts[:param_name] }
      end
    end
  end
end

