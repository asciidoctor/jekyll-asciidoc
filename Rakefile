require 'rake/clean'

default_tasks = []

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new :spec
  default_tasks << :spec
rescue LoadError
end

begin
  require 'bundler/gem_tasks'
  default_tasks << :build
rescue LoadError
  warn 'jekyll-asciidoc: Bundler is required to build this gem.
You can install Bundler using the `gem install` command:

 $ [sudo] gem install bundler' + %(\n\n)
end

task :default => default_tasks unless default_tasks.empty?
