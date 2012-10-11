module Omnis
  module MongoReport
    def find
      @input.find(@query.selector, @query.opts.merge(:transformer => @transformer))
    end

    def run
      find.each do |row|
        @output.save(row)
      end
    end
  end
end
