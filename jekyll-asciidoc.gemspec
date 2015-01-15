Gem::Specification.new do |s|
  s.name = 'jekyll-asciidoc'
  s.version = '1.0.0'
  s.summary = 'A Jekyll plugin that converts AsciiDoc files in your site source to HTML pages using Asciidoctor.'
  s.description = 'A Jekyll plugin that converts AsciiDoc files in your site source to HTML pages using Asciidoctor.'
  s.authors = ['Dan Allen']
  s.email = ['dan.j.allen@gmail.com']
  s.homepage = 'https://github.com/asciidoctor/jekyll-asciidoc'
  s.license = 'MIT'

  begin
    s.files = `git ls-files -z -- */* {CHANGELOG,LICENSE,README,Rakefile}*`.split "\0"
  rescue
    s.files = Dir['**/*']
  end
  
  s.require_paths = ['lib']

  s.add_runtime_dependency 'asciidoctor', '>= 0.1.4'

  s.add_development_dependency 'rake', '~> 10.0'
  s.add_development_dependency 'jekyll', '> 1.0.0'
end
