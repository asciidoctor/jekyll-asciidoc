require File.expand_path '../lib/jekyll-asciidoc/version', __FILE__

Gem::Specification.new do |s|
  s.name = 'jekyll-asciidoc'
  s.version = Jekyll::AsciiDoc::VERSION
  s.summary = 'A Jekyll plugin that converts AsciiDoc files in your site source to HTML pages using Asciidoctor.'
  s.description = 'A Jekyll plugin that converts AsciiDoc files in your site source to HTML pages using Asciidoctor.'
  s.authors = ['Dan Allen']
  s.email = ['dan.j.allen@gmail.com']
  s.homepage = 'https://github.com/asciidoctor/jekyll-asciidoc'
  s.license = 'MIT'

  s.files = begin
    `git ls-files -z`.split "\0"
  rescue
    Dir['**/*']
  end.grep(/^(?:lib\/.+|Rakefile|(LICENSE|README)\.adoc)$/)
  
  s.require_paths = ['lib']

  s.add_runtime_dependency 'asciidoctor', '>= 0.1.4'
  s.add_runtime_dependency 'jekyll', '>= 2.0.0'

  s.add_development_dependency 'rake'
end
