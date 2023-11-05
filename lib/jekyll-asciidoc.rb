# frozen_string_literal: true

module Jekyll
  module AsciiDoc
    jekyll_gem_version = ::Gem::Version.new ::Jekyll::VERSION
    Jekyll3_0 = (::Gem::Requirement.new '~> 3.0.0').satisfied_by? jekyll_gem_version
    Jekyll3_1 = !Jekyll3_0 && ((::Gem::Requirement.new '~> 3.1.0').satisfied_by? jekyll_gem_version)
  end
end
require_relative 'jekyll-asciidoc/jekyll_ext'
require_relative 'jekyll-asciidoc/utils'
require_relative 'jekyll-asciidoc/mixins'
require_relative 'jekyll-asciidoc/excerpt'
require_relative 'jekyll-asciidoc/converter'
require_relative 'jekyll-asciidoc/integrator'
require_relative 'jekyll-asciidoc/filters'
