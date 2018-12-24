source 'https://rubygems.org'
gemspec

gem 'jekyll', %(~> #{ENV['JEKYLL_VERSION']}) if ENV.key? 'JEKYLL_VERSION'
gem 'pygments.rb', '~> 1.2.1'
# NOTE Windows does not include zoneinfo files, so load tzinfo-data gem
gem 'tzinfo-data', platform: [ :x64_mingw, :mingw ]
