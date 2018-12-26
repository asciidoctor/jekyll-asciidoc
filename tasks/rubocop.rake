begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new :lint
rescue LoadError => e
  task :lint do
    raise 'Failed to load lint task.
Install required gems using: bundle --path=.bundle/gems
Then, invoke Rake using: bundle exec rake', cause: e
  end
end
