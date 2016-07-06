require File.expand_path '../lib/jekyll-asciidoc/version', __FILE__

Gem::Specification.new do |s|
  s.name = 'jekyll-asciidoc'
  s.version = Jekyll::AsciiDoc::VERSION
  s.summary = 'A Jekyll plugin that converts AsciiDoc source files in your site to HTML pages using Asciidoctor.'
  s.description = 'A Jekyll plugin that converts AsciiDoc source files in your site to HTML pages using Asciidoctor.'
  s.authors = ['Dan Allen', 'Paul Rayner']
  s.email = ['dan.j.allen@gmail.com']
  s.homepage = 'https://github.com/asciidoctor/jekyll-asciidoc'
  s.license = 'MIT'

  files = begin
    output = IO.popen('git ls-files -z', err: File::NULL) {|io| io.read }.split %(\0)
    $?.success? ? output : Dir['**/*']
  rescue
    Dir['**/*']
  end
  s.files = files.grep /^(?:lib\/.+|Gemfile|Rakefile|(CHANGELOG|LICENSE|README)\.adoc|#{s.name}\.gemspec)$/
  s.test_files = files.grep /^spec\//
  
  s.require_paths = ['lib']

  s.add_runtime_dependency 'asciidoctor', '>= 1.5.0'
  s.add_runtime_dependency 'jekyll', '>= 2.3.0'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '~> 3.5.0'
  # enable pygments.rb dependency here once https://github.com/tmm1/pygments.rb/pull/162 is merged & released
  #s.add_development_dependency 'pygments.rb', '~> 0.6.3'
end
