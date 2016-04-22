JEKYLL_MIN_VERSION_3 = Gem::Version.new(Jekyll::VERSION) >= Gem::Version.new('3.0.0') unless defined? JEKYLL_MIN_VERSION_3

module Jekyll
  module Converters
    class AsciiDocConverter < Converter
      safe true

      highlighter_prefix "\n"
      highlighter_suffix "\n"

      def initialize(config)
        @config = config
        @config['asciidoc'] ||= 'asciidoctor'
        @config['asciidoc_ext'] ||= 'asciidoc,adoc,ad'
        @asciidoctor_config = (@config['asciidoctor'] ||= {})
        # convert keys to symbols
        @asciidoctor_config.keys.each do |key|
          @asciidoctor_config[key.to_sym] = @asciidoctor_config.delete(key)
        end
        @asciidoctor_config[:safe] ||= 'safe'
        user_defined_attributes = @asciidoctor_config[:attributes]
        @asciidoctor_config[:attributes] = %w(notitle hardbreaks idprefix= idseparator=- linkattrs)
        unless user_defined_attributes.nil?
          @asciidoctor_config[:attributes].concat(user_defined_attributes)
        end
        @asciidoctor_config[:attributes].push('env-jekyll')
      end

      def setup
        return if @setup
        case @config['asciidoc']
          when 'asciidoctor'
            begin
              require 'asciidoctor'
              @setup = true
            rescue LoadError
              STDERR.puts 'You are missing a library required to convert AsciiDoc files. Please run:'
              STDERR.puts '  $ [sudo] gem install asciidoctor'
              raise FatalException.new("Missing dependency: asciidoctor")
            end
          else
            STDERR.puts "Invalid AsciiDoc processor: #{@config['asciidoc']}"
            STDERR.puts "  Valid options are [ asciidoctor ]"
            raise FatalException.new("Invalid AsciiDoc process: #{@config['asciidoc']}")
        end
        @setup = true
      end
      
      def matches(ext)
        rgx = "\.(#{@config['asciidoc_ext'].tr ',', '|'})$"
        ext =~ Regexp.new(rgx, Regexp::IGNORECASE)
      end

      def output_ext(ext)
        '.html'
      end

      def convert(content)
        setup
        case @config['asciidoc']
        when 'asciidoctor'
          Asciidoctor.convert(content, @config['asciidoctor'])
        else
          warn 'Unknown AsciiDoc converter. Passing through raw content.'
          content
        end
      end

      def load(content)
        setup
        case @config['asciidoc']
        when 'asciidoctor'
          Asciidoctor.load(content, :parse_header_only => true)
        else
          warn 'Unknown AsciiDoc converter. Cannot load document header.'
          nil
        end
      end
    end
  end

  module Generators
    # Promotes select AsciiDoc attributes to Jekyll front matter
    class AsciiDocPreprocessor < Generator
      def generate(site)
        asciidoc_converter = JEKYLL_MIN_VERSION_3 ?
            site.find_converter_instance(Jekyll::Converters::AsciiDocConverter) :
            site.getConverterImpl(Jekyll::Converters::AsciiDocConverter)
        asciidoc_converter.setup
        key_prefix = (site.config['asciidoc_key_prefix'] || 'jekyll-')
        key_prefix_len = key_prefix.length
        site.pages.each do |page|
          if asciidoc_converter.matches(page.ext)
            doc = asciidoc_converter.load(page.content)
            next if doc.nil?

            page.data['title'] ||= doc.doctitle
            page.data['author'] = doc.author unless doc.author.nil?

            doc.attributes.each do |key, val|
              if key.start_with?(key_prefix)
                page.data[key[key_prefix_len..-1]] ||= val
              end
            end

            unless page.data.has_key? 'layout'
              if doc.attr? 'page-layout'
                page.data['layout'] ||= doc.attr 'page-layout'
              else
                page.data['layout'] ||= 'default'
              end
            end
          end
        end
        (JEKYLL_MIN_VERSION_3 ? site.posts.docs : site.posts).each do |post|
          if asciidoc_converter.matches(JEKYLL_MIN_VERSION_3 ? post.data['ext'] : post.ext)
            doc = asciidoc_converter.load(post.content)
            next if doc.nil?

            post.data['title'] ||= doc.doctitle
            post.data['author'] = doc.author unless doc.author.nil?
            # TODO carry over date
            # setting categories doesn't work here, we lose the post
            #post.data['categories'] ||= (doc.attr 'categories') if (doc.attr? 'categories')

            doc.attributes.each do |key, val|
              if key.start_with?(key_prefix)
                post.data[key[key_prefix_len..-1]] ||= val
              end
            end

            unless post.data.has_key? 'layout'
              if doc.attr? 'page-layout'
                post.data['layout'] ||= doc.attr 'page-layout'
              else
                post.data['layout'] ||= 'post'
              end
            end
          end
        end
      end
    end
  end

  module Filters
    # Convert an AsciiDoc string into HTML output.
    #
    # input - The AsciiDoc String to convert.
    #
    # Returns the HTML formatted String.
    def asciidocify(input)
      site = @context.registers[:site]
      converter = JEKYLL_MIN_VERSION_3 ?
          site.find_converter_instance(Jekyll::Converters::AsciiDocConverter) :
          site.getConverterImpl(Jekyll::Converters::AsciiDocConverter)
      converter.convert(input)
    end
  end
end
