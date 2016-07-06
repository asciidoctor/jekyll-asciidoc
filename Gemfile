source 'https://rubygems.org'
gemspec

gem 'jekyll', %(~> #{ENV['JEKYLL_VERSION']}) if ENV.key? 'JEKYLL_VERSION'

if RUBY_ENGINE == 'jruby'
  gem 'pygments.rb', github: 'mojavelinux/pygments.rb', branch: 'support-jruby'
else
  gem 'pygments.rb', '~> 0.6.3'
end
