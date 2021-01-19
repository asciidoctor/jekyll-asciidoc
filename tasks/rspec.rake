begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new :spec do |t|
    t.verbose = true
    rspec_opts = %W[-f progress #{Random.rand 1000}]
    rspec_opts.unshift '-w' if !ENV['CI'] || ENV['COVERAGE']
    t.rspec_opts = rspec_opts
  end
rescue LoadError => e
  task :spec do
    raise 'Failed to load spec task.
Install required gems using: bundle --path=.bundle/gems
Then, invoke Rake using: bundle exec rake', cause: e
  end
end
