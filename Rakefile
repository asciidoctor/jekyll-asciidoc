require 'rake/clean'

default_tasks = []

begin
  require 'bundler/gem_tasks'
  default_tasks << :build
rescue LoadError
end

task :default => default_tasks unless default_tasks.empty?
