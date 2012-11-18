# Omnis
The goal is to simplify standard and repetetive queries to Mongo and presenting their results.  
To do this Omnis provides a Query and a Transformer, both can be configured using a DSL.

## Query
Converts a params Hash into Operators to be able to easily build queries against databases et al. This is a generic way to process incoming parameters.

```ruby
{ "ref_anixe" => "1abc"}
```
becomes
```ruby
Matches.new(:ref_anixe, "1abc")
```

Example:
```ruby
class SomeQuery
  include Omnis::Query

  def self.parse_date(params, name)
    param = params[name]
    return nil if param.nil?
    time = Time.parse(param)
    Between.new(name, time.getlocal.beginning_of_day..time.getlocal.end_of_day)
  end

  param :ref_anixe, Matches
  param :passenger, Equals
  param(:date, Between) {|params| self.parse_date(params, :date) }
end
```

If a lambda used for extraction returns `nil`, the parameter will be removed.

Params also support defaults as values or as lambdas which will be executed at the time the extraction of the values happens. This way you can build pre-defined queries and if required only override some values. The difference to normal blocks for extraction is that, the latter is not called if the param is not in the inputs - in this case the default will be used.

```ruby
  param :date_from, Between, :default => Between.new("services.date_from", tomorrow.beginning_of_day..tomorrow.end_of_day)
  param :contract,  Matches, :default => "^wotra."
```

## MongoQuery
This covers a standard use case where you have a bunch of params in a Hash, for instance from a web request and you need validation, and transformation of the incoming values.  
No actual calls to mongo are done.

Example:
```ruby
class BookingQuery
  include Omnis::MongoQuery

  # collection Mongo::Connection.new['bms']['bookings'] # planned!?

  param :ref_anixe,   Equals
  param :contract,    Matches
  param :description, Matches
  param :status,      Matches
  param :product,     BeginsWith
  param :agency,      Equals

  # if this param is in the query, fetch the field "ref_customer"
  param :ref_customer, Matches, :field => "ref_customer"

  # those fields are always fetched
  fields   %w[ref_anixe contract description status product agency passengers date_status_modified services]
end
```

Usage:
```ruby
query = BookingQuery.new("ref_anixe" => "1abc", "product" => "HOT")
mongo = query.to_mongo
Mongo::Connection.new['bms']['bookings'].find(mongo.selector, mongo.opts)
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

  property :ref            # if no extra params are provided it will call self.ref at runtime

  to_value {|i| i.upcase } # apply this lambda to all extraced values

  def self.ref(src)
    extract(src, 'ref')
  end
end
```

Usage:
```ruby
transformer = BookingTransformer.new
transformer.transform(doc)
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

## Putting it all together

```ruby
query       = BookingQuery.new("ref_anixe" => "1abc", "product" => "HOT").to_mongo
transformer = BookingTransformer.new.to_proc
collection  = Mongo::Connection.new['bms']['bookings']

table       = collection.find(query.selector, query.opts.merge(:transformer => transformer))

table = Omnis::MongoTable.new(connection, params, BookingQuery, BookingTransformer)

table.call.each do |row|
  row.
end
```

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
