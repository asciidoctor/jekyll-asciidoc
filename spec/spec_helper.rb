require 'jekyll'
require 'fileutils'

Jekyll.logger.log_level = :error

RSpec.configure do |config|
  def fixture_site_params path
    {
      'source' => source_dir(path),
      'destination' => output_dir(path),
      'url' => 'http://example.org'
    }
  end

  def source_dir(path)
    File.join(File.expand_path('../fixtures', __FILE__), path)
  end

  def source_file(path)
    File.join(site.config['source'], path)
  end

  def output_dir(path = nil)
    base = File.expand_path('../../build/test-output', __FILE__)
    path ? File.join(base, path) : base
  end

  def output_file(path)
    File.join(site.config['destination'], path)
  end

  def find_page(path)
    site.pages.find {|p| p.path == path }
  end

  def find_post(path)
    path = %(_posts/#{path}) unless path.start_with?('_posts/')
    site.posts.docs.find {|p| p.relative_path == path }
  end

  FileUtils.rm_rf(output_dir)
end
