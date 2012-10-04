# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'omnis/version'

Gem::Specification.new do |gem|
  gem.name          = "omnis"
  gem.version       = Omnis::VERSION
  gem.authors       = ["Piotr Zolnierek"]
  gem.email         = ["pz@anixe.pl"]
  gem.description   = %q{Helps a read-only ORM kind-of}
  gem.summary       = %q{see above}
  gem.homepage      = "http://github.com/pzol/omnis"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.add_development_dependency 'rspec', '>=2.9.0'
  gem.add_development_dependency 'guard'
  gem.add_development_dependency 'guard-rspec'
  gem.add_development_dependency 'guard-bundler'
  gem.add_development_dependency 'growl'
  gem.add_development_dependency 'activesupport'
  gem.add_development_dependency 'rake'
end
