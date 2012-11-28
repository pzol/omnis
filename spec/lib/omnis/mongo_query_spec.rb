require 'spec_helper'
require 'omnis/operators'
require 'omnis/query'
require 'omnis/mongo_query'
require 'active_support/core_ext/date/calculations'
require 'active_support/core_ext/time/calculations'

describe Omnis::MongoQuery do
  class TestIntegrationQuery
    include Omnis::MongoQuery

    # collection Mongo::Connection.new['bms']['bookings']
    def self.parse_date(params, name)
      param = params[name]
      return nil if param.nil?
      time = Time.parse(param)
      Between.new(name, time.beginning_of_day..time.end_of_day)
    end

    param :ref_anixe,   Equals
    param(:date, Between) {|source| parse_date(source, :date)}
    param :contract,    Matches
    param :description, Matches
    param :status,      Matches
    param :product,     BeginsWith
    param :agency,      Equals

    page  :page, :items_per_page => 20

    # those fields are always fetched
    fields   %w[ref_anixe contract description status product agency passengers date_status_modified services]
  end

  it "works altogether" do
    m = TestIntegrationQuery.new("ref_anixe" => "1abc", "contract" => "test", "product" => "HOT", "page" => "2", "date" => "2012-10-12").to_mongo
    m.selector.should == { :ref_anixe => "1abc",
                           :contract  => /test/i,
                            :product   => /^HOT/i,
                            :date      => { :'$gte' => Time.local(2012, 10, 12, 0, 0, 0), :'$lt' => Time.local(2012, 10, 12, 23, 59, 59, 999999.999)}
                          }

    fields = %w[ref_anixe contract description status product agency passengers date_status_modified services]
    m.opts.should == { :limit => 20, :skip => 40, :fields => fields}
    m.param_names.should == [:ref_anixe, :date, :contract, :product]
  end

  context 'fields' do
    class TestFieldsQuery
      include Omnis::MongoQuery

      fields %w[ref_anixe status]
      # if this param is in the query, fetch the field "ref_customer"
      param :ref_customer, Matches, :field => 'ref_customer'
      param(:date_booked,  Between, :field => 'date_booked') {|src| Between.new(:date_booked, Time.at(0)..Time.at(1), :field => 'date_booked') }
    end

    it 'extra field not requested when param not present' do
      m = TestFieldsQuery.new({}).to_mongo
      m.selector.should == {}
      m.opts.should == { :limit => 20, :skip => 0, :fields => ['ref_anixe', 'status']}
    end

    it 'extra field is requested when param is in request' do
      m = TestFieldsQuery.new({"ref_customer" => "123"}).to_mongo
      m.selector.should == {:ref_customer => /123/i}
      m.opts.should == { :limit => 20, :skip => 0, :fields => ['ref_anixe', 'status', 'ref_customer']}
    end

    it 'works with lambdas, but the lambda must provide the opts!' do
      m = TestFieldsQuery.new({"date_booked" => "1NOV"}).to_mongo
      m.selector
      m.opts.should == { :limit => 20, :skip => 0, :fields => ['ref_anixe', 'status', 'date_booked']}
    end
  end

  context 'paging' do
    class TestPageDefaultQuery
      include Omnis::MongoQuery
    end

    it "page 0 is treated like page 1" do
      t = TestPageDefaultQuery.new({'page' => 0})
      t.to_mongo.opts.should == { :limit => 20, :skip => 0, :fields => []}
    end

    it "page default no page number given" do
      t = TestPageDefaultQuery.new({})
      t.to_mongo.opts.should == { :limit => 20, :skip => 0, :fields => []}
    end

    it "page defaults and page given" do
      t = TestPageDefaultQuery.new({"page" => 2})
      t.to_mongo.opts.should == { :limit => 20, :skip => 40, :fields => []}
    end

    it "works with a custom paging param" do
      class TestPageCustomPagingParamQuery
        include Omnis::MongoQuery
        page :fancy_pants, :items_per_page => 20
      end

      m = TestPageCustomPagingParamQuery.new("fancy_pants" => 2).to_mongo
      m.opts.should == { :limit => 20, :skip => 40, :fields => []}
    end
  end

  context 'sorting' do
    class TestSortQuery
      include Omnis::MongoQuery
      param :ref_provider,  Equals, :field => 'services.ref_provider'
      param :ref_anixe,     Equals
      param :name,          Equals
      sort :sort, :default => [:ref_anixe, :asc]
    end

    it 'default sort order' do
      m = TestSortQuery.new({}).to_mongo
      m.opts[:sort].should == [:ref_anixe, :asc]
    end

    it 'ascending by default' do
      m = TestSortQuery.new("sort" => "name").to_mongo
      m.opts[:sort].should == ['name', :asc]
    end

    it 'ascending for invalid sort order' do
      m = TestSortQuery.new("sort" => "name,kupa").to_mongo
      m.opts[:sort].should == ['name', :asc]
    end

    it 'ascending' do
      m = TestSortQuery.new("sort" => "name,asc").to_mongo
      m.opts[:sort].should == ['name', :asc]
    end

    it 'descending' do
      m = TestSortQuery.new("sort" => "name,desc").to_mongo
      m.opts[:sort].should == ['name', :desc]
    end

    it 'uses the supplied optional field for sorting' do
      m = TestSortQuery.new("sort" => "ref_provider").to_mongo
      m.opts[:sort].should == ['services.ref_provider', :asc]
    end

    it 'works with a custom sorting param' do
      class TestSortCustomQuery
        include Omnis::MongoQuery
        param :name,      Equals
        sort :fancy_pants, :default => [:ref_anixe, :asc]
      end
      m = TestSortCustomQuery.new("fancy_pants" => "name,desc").to_mongo
      m.opts[:sort].should == ['name', :desc]
    end
  end

  context 'practical use case with predefined params' do
    class TestHotelsWithDepartureTomorrowQuery
      include Omnis::MongoQuery
      def self.tomorrow
        Time.new(2012, 10, 12, 22, 54, 38)
      end

      param :date_from, Between, :default => Between.new("services.date_from", tomorrow.beginning_of_day..tomorrow.end_of_day)
      param :contract,  Matches, :default => "^wotra."
      param :product,   Equals,  :default => "PACKAGE"
      param :status,    Equals,  :default => "book_confirmed"

      page :page, :items_per_page => 9999
      fields %w[ref_anixe ref_customer status passengers date_status_modified description contract agency services]
    end

    it "should fill params with default" do
      t = TestHotelsWithDepartureTomorrowQuery.new({})
      m = t.to_mongo
      m.selector[:contract].should == /^wotra./i
      m.selector[:product].should  == "PACKAGE"
      m.selector[:status].should   == "book_confirmed"
      m.selector['services.date_from'].should == {:'$gte' => Time.new(2012, 10, 12), :'$lt' => Time.local(2012, 10, 12, 23, 59, 59, 999999.999)}
      m.opts[:limit].should  == 9999
      m.opts[:skip].should   == 0
      m.opts[:fields].should == ["ref_anixe", "ref_customer", "status", "passengers", "date_status_modified", "description", "contract", "agency", "services"]
    end
  end
end
