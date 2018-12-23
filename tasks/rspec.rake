begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new :spec
rescue LoadError => e
  task :spec do
    raise 'Failed to load spec task.
Install required gems using: bundle --path=.bundle/gems
Then, invoke Rake using: bundle exec rake', cause: e
  end
end
