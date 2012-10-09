require 'monadic'

module Omnis
  class NestedHashExtractor
    # returns a lambda which extracts a value from a nested hash
    def extractor(path)
      raise ArgumentError("path to extract must be a string") unless String === path
      expr = "source#{from_dot_path(path)} rescue Nothing"
      ->source { eval(expr) }
    end

    private
    # convert from a path to a ruby expression (as string)
    def from_dot_path(path)
      return nil if path.nil?
      path.split('.').map {|i| field(i) }.join
    end

    def field(f)
      return '['  << f << ']' if is_i?(f)
      return '.fetch("' << f << '", Nothing)'
    end

    # checks if the string is a number
    def is_i?(s)
     !!(s =~ /^[-+]?[0-9]+$/)
   end
 end
end
