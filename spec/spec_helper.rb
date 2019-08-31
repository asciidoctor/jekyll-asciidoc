if ENV['COVERAGE'] == 'deep'
  ENV['DEEP_COVER'] = 'true'
  require 'deep_cover'
elsif ENV['COVERAGE'] == 'true'
  require 'deep_cover/builtin_takeover'
  require 'simplecov'
end

require 'jekyll'
require 'fileutils'

Jekyll.logger.log_level = :error

RSpec.configure do |config|
  config.before :suite do
    ::FileUtils.rm_rf output_dir
    if ENV['JEKYLL_VERSION'] == '3.0.0'
      plugins_rx = /([*&])?plugins(:)?/
      plugins_to_gems_sub = '\1gems\2'
      Dir[%(#{fixtures_dir}/**/_config.yml)].each do |filename|
        ::File.write filename, ((::File.read filename).gsub plugins_rx, plugins_to_gems_sub)
      end
    end
  end

  config.after :suite do
    if ENV['JEKYLL_VERSION'] == '3.0.0'
      gems_rx = /([*&])?gems(:)?/
      gems_to_plugins_sub = '\1plugins\2'
      Dir[%(#{fixtures_dir}/**/_config.yml)].each do |filename|
        ::File.write filename, ((::File.read filename).gsub gems_rx, gems_to_plugins_sub)
      end
    else
      Dir[%(#{fixtures_dir}/**/.jekyll-cache)].each {|dirname| FileUtils.rm_rf dirname }
    end
  end

  def use_fixture name
    let (:name) { name.to_s }
  end

  def fixture_site_params path
    {
      'source' => (source_dir path),
      'destination' => (output_dir path),
      'url' => 'http://example.org',
    }
  end

  def source_dir path
    ::File.join fixtures_dir, path
  end

  def source_file path
    ::File.join site.config['source'], path
  end

  def fixtures_dir
    ::File.absolute_path 'fixtures', __dir__
  end

  def output_dir path = nil
    base = ::File.absolute_path '../build/test-output', __dir__
    path ? (::File.join base, path) : base
  end

  def output_file path
    ::File.join site.config['destination'], path
  end

  def find_page path
    site.pages.find {|p| p.path == path }
  end

  def find_post path
    path = %(_posts/#{path}) unless path.start_with? '_posts/'
    site.posts.docs.find {|p| p.relative_path == path }
  end

  def find_draft path
    path = %(_drafts/#{path}) unless path.start_with? '_drafts/'
    site.posts.docs.find {|p| p.relative_path == path }
  end

  def find_doc path, collection_name
    path = %(_#{collection_name}/#{path}) unless path.start_with? %(_#{collection_name}/)
    site.collections[collection_name].docs.find {|p| p.relative_path == path }
  end

  def windows?
    /win|ming/ =~ ::RbConfig::CONFIG['host_os']
  end
end
