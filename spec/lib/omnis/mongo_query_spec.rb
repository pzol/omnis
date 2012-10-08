require 'spec_helper'
require 'omnis/operators'
require 'omnis/query'
require 'active_support/core_ext/hash'

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
      def page
        @input_params[page_param_name].to_i
      end

      def page_param_name
        self.class.page_param_name || :page
      end

      def items_per_page
        self.class.items_per_page || 20
      end

      def mongo_selector
        Hash[params.map { |operator| [operator.key, mongo_operator(operator)] }]
      end

      def mongo_operator(operator)
        case operator
        when Equals;      operator.value
        when Matches;     /#{operator.value}/i
        when BeginsWith;  /^#{operator.value}/i
        end
      end

      def mongo_opts
        { :limit => items_per_page, :skip => skip, :fields => self.class.field_list }
      end

      def skip
        (page - 1) * items_per_page
      end
    end
  end
end

describe Omnis::MongoQuery do
  class TestIntegrationQuery
    include Omnis::MongoQuery

    # collection Mongo::Connection.new['bms']['bookings']

    param :ref_anixe,   Equals
    param :contract,    Matches
    param :description, Matches
    param :status,      Matches
    param :product,     BeginsWith
    param :agency,      Equals

    # if this param is in the query, fetch the field "ref_customer"
    param :ref_customer, Matches, :field => "ref_customer"

    page  :page, :items_per_page => 20

    # those fields are always fetched
    fields   %w[ref_anixe contract description status product agency passengers date_status_modified services]
  end

  it "works alltogether" do
    t = TestIntegrationQuery.new("ref_anixe" => "1abc", "contract" => "test", "product" => "HOT", "page" => "2")
    p t.params
    t.mongo_selector.should == { :ref_anixe => "1abc",
                                 :contract  => /test/i,
                                 :product   => /^HOT/i }

    fields = %w[ref_anixe contract description status product agency passengers date_status_modified services]
    t.mongo_opts.should == { :limit => 20, :skip => 20, :fields => fields}
  end

  it "page default :page and 20 items per page" do
  end
end
