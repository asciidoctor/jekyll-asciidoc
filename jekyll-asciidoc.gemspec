require File.expand_path '../lib/jekyll-asciidoc/version', __FILE__

Gem::Specification.new do |s|
  s.name = 'jekyll-asciidoc'
  s.version = Jekyll::AsciiDoc::VERSION
  s.summary = 'A Jekyll plugin that converts the AsciiDoc source files in your site to HTML pages using Asciidoctor.'
  s.description = 'A Jekyll plugin that converts the AsciiDoc source files in your site to HTML pages using Asciidoctor.'
  s.authors = ['Dan Allen', 'Paul Rayner']
  s.email = ['dan.j.allen@gmail.com']
  s.homepage = 'https://github.com/asciidoctor/jekyll-asciidoc'
  s.license = 'MIT'
  # NOTE the required ruby version is informational only
  # it matches the minimum version required by Jekyll
  # we don't enforce it because it can't be overridden and can cause builds to break
  #s.required_ruby_version = '>= 2.1.0'

  files = begin
    output = IO.popen('git ls-files -z', err: File::NULL) {|io| io.read }.split %(\0)
    $?.success? ? output : Dir['**/*']
  rescue
    Dir['**/*']
  end
  s.files = files.grep %r/^(?:lib\/.+|Gemfile|Rakefile|(?:CHANGELOG|LICENSE|README)\.adoc|#{s.name}\.gemspec)$/
  s.test_files = files.grep %r/^spec\//

  s.require_paths = ['lib']

  s.add_runtime_dependency 'asciidoctor', '>= 1.5.0'
  s.add_runtime_dependency 'jekyll', '>= 2.3.0'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '~> 3.5.0'
end
