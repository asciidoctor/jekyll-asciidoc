source 'https://rubygems.org'
gemspec

gem 'jekyll', %(~> #{ENV['JEKYLL_VERSION']}) if ENV.key? 'JEKYLL_VERSION'
# NOTE Windows does not include zoneinfo files, so load tzinfo-data gem
gem 'tzinfo-data', platform: :mingw

if (ENV.key? 'JEKYLL_VERSION') && (Gem::Version.new ENV['JEKYLL_VERSION']) < (Gem::Version.new '3.0.0')
  if (Gem::Version.new RUBY_VERSION) < (Gem::Version.new '2.0.0')
    # NOTE downgrade ffi to support Ruby 1.9.3
    gem 'ffi', '1.9.14', platform: :mingw
    # NOTE downgrade octokit to support Ruby 1.9.3
    gem 'octokit', '~> 4.2.0'
  end
  # NOTE pygments.rb 0.6.3 is not compatible with Ruby >= 2.4
  gem 'pygments.rb', '~> 0.6.3'
else
  # NOTE pygments.rb >= 1.1.0 includes support for JRuby
  gem 'pygments.rb', '~> 1.1.1'
end
