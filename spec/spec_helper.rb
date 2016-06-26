require 'jekyll'
require 'fileutils'

Jekyll::MIN_VERSION_3 = Gem::Version.new(Jekyll::VERSION) >= Gem::Version.new('3.0.0') unless defined?(Jekyll::MIN_VERSION_3)
Jekyll.logger.log_level = :error

# NOTE reset hook callbacks each time site is reset
module Jekyll
  module Hooks
    # deep dup hashes and shallow dup the leaves
    def self.deep_dup(h)
      h.each_with_object({}) {|(k, v), new_h| new_h[k] = ::Hash === v ? deep_dup(v) : v.dup }
    end

    def self.reset site
      @registry = deep_dup(@initial_registry)
    end

    register(:site, :after_reset, &method(:reset))
    @initial_registry = deep_dup(@registry)
  end
end if defined?(Jekyll::Hooks)

RSpec.configure do |config|
  config.before(:suite) do
    ::FileUtils.rm_rf(output_dir)
  end

  def fixture_site_params path
    {
      'source' => source_dir(path),
      'destination' => output_dir(path),
      'url' => 'http://example.org'
    }
  end

  def source_dir(path)
    ::File.join(::File.expand_path('../fixtures', __FILE__), path)
  end

  def source_file(path)
    ::File.join(site.config['source'], path)
  end

  def output_dir(path = nil)
    base = ::File.expand_path('../../build/test-output', __FILE__)
    path ? ::File.join(base, path) : base
  end

  def output_file(path)
    ::File.join(site.config['destination'], path)
  end

  def find_page(path)
    site.pages.find {|p| p.path == path }
  end

  def find_post(path)
    path = %(_posts/#{path}) unless path.start_with?('_posts/')
    (::Jekyll::MIN_VERSION_3 ? site.posts.docs : site.posts).find {|p| p.relative_path == path }
  end

  def find_draft(path)
    path = %(_drafts/#{path}) unless path.start_with?('_drafts/')
    path = %(/#{path}) unless ::Jekyll::MIN_VERSION_3
    (::Jekyll::MIN_VERSION_3 ? site.posts.docs : site.posts).find {|p| p.relative_path == path }
  end

  def find_doc(path, collection_name)
    path = %(_#{collection_name}/#{path}) unless path.start_with?(%(_#{collection_name}/))
    site.collections[collection_name].docs.find {|p| p.relative_path == path }
  end
end
