# Omnis
The goal is to simplify standard and repetetive queries to Mongo and presenting their results.  
To do this Omnis provides a Query and a Transformer, both can be configured using a DSL.

## Query
Converts a params Hash into Operators to be able to easily build queries against databases et al.

```ruby
{ "ref_anixe" => "1abc"}
```
becomes
```ruby
Matches.new(:ref_anixe, "1abc")
```

## MongoQuery
This covers a standard use case where you have a bunch of params in a Hash, for instance from a web request and you need validation, and transformation of the incoming values.

Example:
```ruby
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

  param :contract,  Matches
  param(:date_from) {|value| parse_date(value) }
  param(:date_to)   {|value| parse_date(value) }

  fields   %w[ref_anixe ref_customer status passengers date_status_modified date_from date_to description product contract agency services]
end
```

## Transformer
Transforms some data into another form of (flattened) data. Extractors can be used to get values from the data source.  
If the first parameter of a property denotes the output field, the second is a string which is passed as argument to the extractor.

Example:
```ruby
class BookingTransformer
  include Omnis::DataTransformer
  extractor Omnis::NestedHashExtractor.new

  property :ref_anixe,    "ref_anixe"
  property :ref_customer, "ref_customer"
  property :status,       "status"
  property(:passenger)     {|doc| Maybe(doc)['passengers'].map {|v| v.first.values.slice(1..2).join(' ') }.or('Unknown').fetch.to_s }
  property :date          "date_status_modified", :default => Time.at(0), :format => ->v { v.to_s(:date) }
  property :description,  "description"
  property :product,      "product"
  property :contract,     "contract"
  property :agency,       "agency"
  property :date_from,    "services.0.date_from", :default => "n/a", :format => ->v { v.to_s(:date) }
  property :date_to,      "services.0.date_to",   :default => "n/a", :format => ->v { v.to_s(:date) }
end
```
This will produce a Hash like `{:ref_anixe => "1abc", :status => "book_confirmed" ... }`

If you provide blocks for all properties, an Extractor is not required

```ruby
class ExtractorlessTransformer
  include Omnis::DataTransformer
  property(:ref) {|src| src["ref_anixe"] }
end
```

If you provide a `#to_object(hash)` method in the Transformer definition, it will be used to convert the output Hash into the object of you desire.

## Using it all together
TODO

## Installation

Add this line to your application's Gemfile:

    gem 'omnis'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install omnis

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
