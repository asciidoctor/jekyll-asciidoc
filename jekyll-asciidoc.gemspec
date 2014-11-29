Gem::Specification.new do |s|
  s.name        = 'jekyll-asciidoc'
  s.version     = '0.0.1'
  s.summary     = "A Jekyll plugin that converts AsciiDoc files in your site source to HTML pages using Asciidoctor."
  s.authors     = ["Dan Allen"]
  s.email       = ''
  s.files       = ["lib/jekyll-asciidoc.rb"]
  s.homepage    = 'https://github.com/asciidoctor/jekyll-asciidoc'
  s.license     = 'MIT'
	
	s.add_runtime_dependency "asciidoctor", "~> 1.5"
	s.add_development_dependency "jekyll", "~> 2.4"
end
