source 'https://rubygems.org'

gemspec

gem 'asciidoctor', ENV['ASCIIDOCTOR_VERSION'], require: false if ENV.key? 'ASCIIDOCTOR_VERSION'
gem 'jekyll', %(~> #{ENV['JEKYLL_VERSION']}), require: false if ENV.key? 'JEKYLL_VERSION'
gem 'pygments.rb', '~> 1.2.1', require: false
gem 'rubocop', '~> 0.61.1', require: false
# NOTE Windows does not include zoneinfo files, so load tzinfo-data gem
gem 'tzinfo-data', platform: [:x64_mingw, :mingw], require: false

group :docs do
  gem 'yard', require: false
end
