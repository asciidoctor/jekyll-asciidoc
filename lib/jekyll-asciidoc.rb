module Jekyll
  module AsciiDoc
    Jekyll3_1 = (::Gem::Requirement.new '~> 3.1.0').satisfied_by? ::Gem::Version.new ::Jekyll::VERSION
  end
end
require_relative 'jekyll-asciidoc/core_ext'
require_relative 'jekyll-asciidoc/jekyll_ext'
require_relative 'jekyll-asciidoc/utils'
require_relative 'jekyll-asciidoc/mixins'
require_relative 'jekyll-asciidoc/converter'
require_relative 'jekyll-asciidoc/integrator'
require_relative 'jekyll-asciidoc/filters'
