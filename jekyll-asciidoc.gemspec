require File.absolute_path 'lib/jekyll-asciidoc/version', __dir__
require 'open3' unless defined? Open3

Gem::Specification.new do |s|
  s.name = 'jekyll-asciidoc'
  s.version = Jekyll::AsciiDoc::VERSION
  s.summary = 'A Jekyll plugin that converts the AsciiDoc source files in your site to HTML pages using Asciidoctor.'
  s.description = s.summary

  s.authors = ['Dan Allen', 'Paul Rayner']
  s.email = ['dan.j.allen@gmail.com']
  s.homepage = 'https://github.com/asciidoctor/jekyll-asciidoc'
  s.license = 'MIT'
  s.metadata = {
    'bug_tracker_uri' => 'https://github.com/asciidoctor/jekyll-asciidoc/issues',
    'changelog_uri' => 'https://github.com/asciidoctor/jekyll-asciidoc/blob/master/CHANGELOG.adoc',
    'mailing_list_uri' => 'http://discuss.asciidoctor.org',
    'source_code_uri' => 'https://github.com/asciidoctor/jekyll-asciidoc',
  }
  # NOTE the required ruby version is informational only
  # it tracks the minimum version required by Jekyll >= 3.0.0 (see https://jekyllrb.com/docs/installation/#requirements)
  # we don't enforce it because it can't be overridden and can cause builds to break
  #s.required_ruby_version = '>= 2.2.0'

  files = begin
    (result = Open3.popen3('git ls-files -z') {|_, out| out.read }.split ?\0).empty? ? Dir['**/*'] : result
  rescue ::SystemCallError
    Dir['**/*']
  end
  s.files = files.grep %r/^(?:lib\/.+|Gemfile|(?:CHANGELOG|LICENSE|README)\.adoc|\.yardopts|jekyll-asciidoc\.gemspec)$/
  #s.test_files = files.grep %r/^spec\/./

  s.require_paths = ['lib']

  s.add_runtime_dependency 'asciidoctor', '~> 2.0'
  s.add_runtime_dependency 'jekyll', '>= 3.0.0'

  s.add_development_dependency 'jekyll-mentions', '~> 1.6.0'
  s.add_development_dependency 'kramdown-parser-gfm', '~> 1.1.0'
  s.add_development_dependency 'pygments.rb', '~> 2.1.0'
  s.add_development_dependency 'rake', '~> 12.3.2'
  s.add_development_dependency 'rspec', '~> 3.8.0'
end
