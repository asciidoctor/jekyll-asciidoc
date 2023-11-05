source 'https://rubygems.org'

gemspec

gem 'asciidoctor', ENV['ASCIIDOCTOR_VERSION'], require: false if ENV.key? 'ASCIIDOCTOR_VERSION'
gem 'jekyll', %(~> #{ENV['JEKYLL_VERSION']}), require: false if ENV.key? 'JEKYLL_VERSION'
# NOTE Windows does not include zoneinfo files, so load tzinfo-data gem
gem 'tzinfo-data', platform: [:x64_mingw, :mingw], require: false

group :coverage do
  gem 'deep-cover-core', '~> 1.1.0', require: false
  gem 'simplecov', '~> 0.18.0', require: false
end

group :docs do
  gem 'yard', require: false
end

group :lint do
  gem 'rubocop', '~> 0.74.0', require: false
end
