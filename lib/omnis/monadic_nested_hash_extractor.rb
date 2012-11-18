require 'monadic'

module Omnis
  class MonadicNestedHashExtractor < NestedHashExtractor
    def extractor(path)
      raise ArgumentError("path to extract must be a string") unless String === path
      expr = "source#{from_dot_path(path)} rescue Nothing"
      ->source { Maybe(eval(expr)) }
    end
  end
end
