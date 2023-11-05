# frozen_string_literal: true

begin
  require 'bundler/gem_tasks'
rescue LoadError
  raise 'Bundler is required to build this gem.
Install Bundler using: gem install bundler
Then, install required gems using: bundle --path=.bundle/gems'
end
