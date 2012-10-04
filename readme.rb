class BookingQuery
  include Omnis::MongoQuery

  collection Mongo::Connection.new['bms']['bookings']

  def parse_date(value)
    case result = Time.parse(value) rescue Chronic.parse(value, :guess => false)
      when Time;          Between.new(m, result.getlocal.beginning_of_day..result.getlocal.end_of_day)
      when Chronic::Span; Between.new(m, result)
      else nil
    end
  end

  param    :contract, Matches
  param    :date_from {|value| parse_date(value) }
  param    :date_to   {|value| parse_date(value) }

  fields   %w[ref_anixe ref_customer status passengers date_status_modified date_from date_to description product contract agency services]
end

class BookingTransformer
  include Omnis::DataTransformer

  def extract_passenger(doc)
    ->doc { Maybe(doc)['passengers'].map {|v| v.first.values.slice(1..2).join(' ') }.or('Unknown').fetch.to_s }
  end

  property :ref_anixe,    "ref_anixe"
  property :ref_customer, "ref_customer"
  property :status,       "status"
  property :passenger,    extract_passenger(doc)
  property :date          "date_status_modified", :default => Time.at(0), :format => ->v { v.to_s(:date) }
  property :description,  "description"
  property :product,      "product"
  property :contract,     "contract"
  property :agency,       "agency"
  property :date_from,    "services.0.date_from", :default => "n/a", :format => ->v { v.to_s(:date) }
  property :date_to,      "services.0.date_to",   :default => "n/a", :format => ->v { v.to_s(:date) }

  def to_object(doc)
    OpenStruct.new(doc)
  end
end

present BookingQuery.new(params), Foo.new(NestedHashExtractor.new)

def present(query, transformer)
  query.call(transformer)
end
