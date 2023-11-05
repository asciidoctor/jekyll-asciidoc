# frozen_string_literal: true

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new :spec do |t|
    t.verbose = true
    t.rspec_opts = [
      $VERBOSE || ENV['COVERAGE'] ? '-w' : nil,
      ENV['CI'] && ENV['COVERAGE'] ? '-fd' : '-fp',
      ENV['GITHUB_RUN_ID'] ? %(--seed #{ENV['GITHUB_RUN_ID']}) : %(--seed #{Random.rand 1000}),
    ].compact.join ' '
  end
rescue LoadError
  warn $!.message
end
