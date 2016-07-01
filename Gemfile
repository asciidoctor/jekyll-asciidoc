source 'https://rubygems.org'
gemspec

if ENV.key?('JEKYLL_VERSION')
  gem 'jekyll', %(~> #{ENV['JEKYLL_VERSION']})
end

gem 'pygments.rb', github: 'mojavelinux/pygments.rb', branch: 'support-jruby', platforms: :jruby
