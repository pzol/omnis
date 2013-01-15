require 'ostruct'
require 'monadic'

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

      attr_reader :page_param_name, :items_per_page,  :sort_param_name, :sort_default_field, :sort_default_order
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

      def sort(sort_param_name, opts={})
        @sort_param_name  = sort_param_name
        @sort_default_field = opts[:default][0]
        @sort_default_order = (opts[:default][1] || :asc).to_sym
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

      def items_per_page
        self.class.items_per_page || 20
      end

      private
      def page
        return 0 unless @input_params.has_key? page_param_name
        page_num = @input_params[page_param_name].to_i
        return 0 if page_num < 0
        return page_num
      end

      def skip
        page * items_per_page
      end

      def page_param_name
        self.class.page_param_name || :page
      end


      def sort_param_name
        self.class.sort_param_name
      end

      def sort_default_field
        self.class.sort_default_field
      end

      def sort_default_order
        self.class.sort_default_order || :asc
      end

      def mongo_operator(operator)
        operator.mongo_value
      end

      def mongo_selector(extracted_operators)
        Hash[extracted_operators.map { |operator| [operator.key, mongo_operator(operator)] }]
      end

      def mongo_opts(extracted_operators)
        {}.tap do |opts|
          params_with_extra_fields = extracted_operators.collect(&:opts).select {|e| e.has_key? :field}
          extra_fields  = params_with_extra_fields.map {|e| e[:field]}
          opts[:fields] = self.class.field_list + extra_fields.flatten
          opts[:limit]  = items_per_page
          opts[:skip]   = skip
          opts[:sort]   = sort_opts if sort_opts.all?
        end
      end

      def sort_opts
        sort_args = (@input_params[sort_param_name] || '').split ','

        sort_order = sort_args[1]
        sort_order ||= sort_default_order
        sort_order = sort_order.to_sym
        sort_order = :asc unless [:asc, :desc].include? sort_order

        @sort_opts = [sort_field(sort_args), sort_order]
      end

      def sort_field(sort_args)
        sort_field   = sort_args[0]
        sort_field ||= sort_default_field
        return nil unless sort_field

        custom_sort_field = get_custom_sort_field(sort_field)

        custom_sort_field ? custom_sort_field : sort_field
      end

      def get_custom_sort_field(sort_field)
        sort_field_param = self.class.params[sort_field.to_sym]
        if sort_field_param && sort_field_param.opts.has_key?(:field)
          sort_field   = sort_field_param.opts[:field]
        end
      end

      def extracted_param_names(extracted_operators)
        extracted_operators.map {|e| e.opts[:param_name] }
      end
    end
  end
end

