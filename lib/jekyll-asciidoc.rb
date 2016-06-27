Jekyll::MIN_VERSION_3 = (Gem::Version.new Jekyll::VERSION) >= (Gem::Version.new '3.0.0') unless defined? Jekyll::MIN_VERSION_3

require_relative 'jekyll-asciidoc/utils'
require_relative 'jekyll-asciidoc/mixins'
require_relative 'jekyll-asciidoc/converter'
require_relative 'jekyll-asciidoc/integrator'
require_relative 'jekyll-asciidoc/filters'
