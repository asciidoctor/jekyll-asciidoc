require File.expand_path '../lib/jekyll-asciidoc/version', __FILE__

require 'rake/clean'

default_tasks = []

begin
  require 'bundler/gem_tasks'

  # Enhance the release task to create an explicit commit for the release
  Rake::Task[:release].enhance [:commit_release]

  # NOTE you don't need to push after updating version and committing locally
  task :commit_release do
    Bundler::GemHelper.new.send :guard_clean
    sh %(git commit --allow-empty -a -m 'Release #{Jekyll::AsciiDoc::VERSION}')
  end

  default_tasks << :build
rescue LoadError
end

task :default => default_tasks unless default_tasks.empty?
