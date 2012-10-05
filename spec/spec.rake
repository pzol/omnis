require 'rspec/core/rake_task'

SPEC_SUITES = [
  { :id => :unit,
    :title => 'unit',
    :files => %w(spec/**/*_spec.rb) },

  { :id => :acceptance,
    :title => 'acceptance',
    :files => %w(spec/acceptance/**/*_spec.rb),
    :opts => '-I spec/acceptance' },
]


namespace :spec do
  SPEC_SUITES.each do |suite|
    desc "Run #{suite[:title]} tests"
    RSpec::Core::RakeTask.new(suite[:id]) do |t|
      spec_files = []
      suite[:files].each { |glob| spec_files += Dir[glob] } if suite[:files]
      t.pattern = spec_files

      t.rspec_opts = suite[:opts] if suite.has_key? :opts
    end
  end
end
