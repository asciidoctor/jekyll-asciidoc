source 'https://rubygems.org'
gemspec

gem 'jekyll', %(~> #{ENV['JEKYLL_VERSION']}) if ENV.key? 'JEKYLL_VERSION'

if (ENV.key? 'JEKYLL_VERSION') && (Gem::Version.new ENV['JEKYLL_VERSION']) < (Gem::Version.new '3.0.0')
  # NOTE pygments.rb 0.6.3 is not compatible with Ruby >= 2.4
  gem 'pygments.rb', '~> 0.6.3'
else
  # NOTE pygments.rb >= 1.1.0 includes support for JRuby
  gem 'pygments.rb', '~> 1.1.1'
end
