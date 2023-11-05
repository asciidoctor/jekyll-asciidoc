# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

gem 'asciidoctor', ENV['ASCIIDOCTOR_VERSION'], require: false if ENV.key? 'ASCIIDOCTOR_VERSION'
gem 'jekyll', %(~> #{ENV['JEKYLL_VERSION']}), require: false if ENV.key? 'JEKYLL_VERSION'
# NOTE Windows does not include zoneinfo files, so load tzinfo-data gem
gem 'tzinfo-data', platform: [:x64_mingw, :mingw], require: false

group :docs do
  gem 'yard', require: false
end

group :lint do
  gem 'rubocop', '~> 1.57.0', require: false
  gem 'rubocop-rake', '~> 0.6.0', require: false
  gem 'rubocop-rspec', '~> 2.25.0', require: false
end
