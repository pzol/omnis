module Omnis
  class NestedHashExtractor
    # returns a lambda which extracts a value from a nested hash
    def extractor(path)
      case path
      when String; ->doc { eval("doc#{from_dot_path(path)} rescue Nothing") }
      else path  # todo
      end
    end

    private
    # convert from a path to a ruby expression (as string)
    def from_dot_path(path)
      return nil if path.nil?
      path.split('.').map {|i| field(i) }.join
    end

    def field(f)
      return '['  << f << ']' if is_i?(f)
      return '["' << f << '"]'
    end

    # checks if the string is a number
    def is_i?(s)
     !!(s =~ /^[-+]?[0-9]+$/)
   end
 end
end
