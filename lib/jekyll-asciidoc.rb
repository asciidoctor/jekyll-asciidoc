module Jekyll
  MIN_VERSION_3 = ::Gem::Version.new(VERSION) >= ::Gem::Version.new('3.0.0') unless defined?(MIN_VERSION_3)

  module AsciiDoc
    module Configuration; end
    module Utils
      def self.has_front_matter?(delegate_method, asciidoc_ext_re, path)
        ::File.extname(path) =~ asciidoc_ext_re ? true : delegate_method.call(path)
      end
    end
  end

  module Converters
    class AsciiDocConverter < Converter
      DEFAULT_ATTRIBUTES = {
        'idprefix' => '',
        'idseparator' => '-',
        'linkattrs' => ''
      }
      IMPLICIT_ATTRIBUTES = {
        'env' => 'site',
        'env-site' => '',
        'site-gen' => 'jekyll',
        'site-gen-jekyll' => '',
        'builder' => 'jekyll',
        'builder-jekyll' => '',
        'jekyll-version' => ::Jekyll::VERSION
      }
      HEADER_BOUNDARY_RE = /(?<=\p{Graph})\n\n/
      STANDALONE_HEADER = %([%standalone]\n)

      safe true

      highlighter_prefix %(\n)
      highlighter_suffix %(\n)

      def initialize(config)
        # NOTE jekyll-watch reinitializes plugins using a shallow clone of config, so no need to reconfigure
        unless ::Jekyll::AsciiDoc::Configuration === (asciidoc_config = (config['asciidoc'] ||= {}))
          if ::String === asciidoc_config
            ::Jekyll.logger.warn('jekyll-asciidoc: The AsciiDoc-related configuration should be defined using a Hash (under the `asciidoc` key) instead of discrete entries.')
            asciidoc_config = config['asciidoc'] = { 'processor' => asciidoc_config }
          else
            asciidoc_config['processor'] ||= 'asciidoctor'
          end
          old_asciidoc_ext = config.delete('asciidoc_ext')
          asciidoc_ext = (asciidoc_config['ext'] ||= (old_asciidoc_ext || 'asciidoc,adoc,ad'))
          asciidoc_ext_re = (asciidoc_config['ext_re'] = /^\.(?:#{asciidoc_ext.tr ',', '|'})$/ix)
          old_page_attr_prefix_def = config.key?('asciidoc_page_attribute_prefix')
          old_page_attr_prefix_val = config.delete('asciidoc_page_attribute_prefix')
          unless (page_attr_prefix = asciidoc_config['page_attribute_prefix'])
            page_attr_prefix = old_page_attr_prefix_def ? (old_page_attr_prefix_val || '') :
                (asciidoc_config.key?('page_attribute_prefix') && '' || 'page')
          end
          asciidoc_config['page_attribute_prefix'] = page_attr_prefix.chomp('-')
          asciidoc_config['require_front_matter_header'] = !!asciidoc_config.fetch('require_front_matter_header', false)

          asciidoctor_config = (config['asciidoctor'] ||= {})
          asciidoctor_config.replace(::Hash[asciidoctor_config.map {|key, val| [key.to_sym, val] }])
          asciidoctor_config[:safe] ||= 'safe'
          asciidoctor_config[:attributes] = DEFAULT_ATTRIBUTES.dup
              .update(coerce_attributes_to_hash(asciidoctor_config[:attributes]))
              .update(IMPLICIT_ATTRIBUTES)

          if ::Jekyll::MIN_VERSION_3 && !asciidoc_config['require_front_matter']
            if (del_method = ::Jekyll::Utils.method(:has_yaml_header?))
              unless (new_method = ::Jekyll::AsciiDoc::Utils.method(:has_front_matter?)).respond_to?(:curry)
                new_method = new_method.to_proc # Ruby < 2.2
              end
              del_method.owner.define_singleton_method(del_method.name, new_method.curry[del_method][asciidoc_ext_re])
            end
          end

          asciidoc_config.extend(::Jekyll::AsciiDoc::Configuration)
        end
        @config = config
        @setup = false
      end

      # TODO remove shadowed entries
      def coerce_attributes_to_hash(attrs)
        if ::Hash === attrs
          ::Hash[attrs.map {|key, val|
            if val
              [key.end_with?('!') ? '!' + key.chop : key, val]
            else
              key = key.chop if key.end_with?('!')
              key = '!' + key unless key.start_with?('!')
              [key, '']
            end
          }]
        else
          Array(attrs || []).inject({}) do |accum, entry|
            key, val = entry.split('=', 2)
            accum[key.end_with?('!') ? '!' + key.chop : key] = val || ''
            accum
          end
        end
      end

      def setup
        return self if @setup
        @setup = true
        case @config['asciidoc']['processor']
        when 'asciidoctor'
          begin
            require 'asciidoctor' unless defined?(::Asciidoctor::VERSION)
          rescue ::LoadError
            ::Jekyll.logger.error('jekyll-asciidoc: You are missing a library required to convert AsciiDoc files. Please install using:')
            ::Jekyll.logger.error('', '$ [sudo] gem install asciidoctor')
            ::Jekyll.logger.abort_with('Bailing out; missing required dependency: asciidoctor')
          end
        else
          ::Jekyll.logger.error(%(jekyll-asciidoc: Invalid AsciiDoc processor given: #{@config['asciidoc']['processor']}))
          ::Jekyll.logger.error('', 'Valid options are: asciidoctor')
          ::Jekyll.logger.abort_with('Bailing out; invalid Asciidoctor processor')
        end
        self
      end

      def matches(ext)
        ext =~ @config['asciidoc']['ext_re']
      end

      def output_ext(ext)
        '.html'
      end

      def convert(content)
        return '' if (content || '').empty?
        setup
        if (standalone = content.start_with?(STANDALONE_HEADER))
          content = content[STANDALONE_HEADER.length..-1]
        end
        case @config['asciidoc']['processor']
        when 'asciidoctor'
          ::Asciidoctor.convert(content, @config['asciidoctor'].merge(header_footer: standalone))
        else
          ::Jekyll.logger.warn(%(jekyll-asciidoc: Unknown AsciiDoc processor: #{@config['asciidoc']['processor']}. Passing through unparsed content.))
          content
        end
      end

      def load_header(content)
        setup
        # NOTE merely an optimization; if this doesn't match, the header still gets isolated by the processor
        header = content.split(HEADER_BOUNDARY_RE, 2)[0]
        case @config['asciidoc']['processor']
        when 'asciidoctor'
          # NOTE return instance even if header is empty since attributes may be inherited from config
          ::Asciidoctor.load(header, @config['asciidoctor'].merge(parse_header_only: true))
        else
          ::Jekyll.logger.warn(%(jekyll-asciidoc: Unknown AsciiDoc processor: #{@config['asciidoc']['processor']}. Cannot load document header.))
        end
      end
    end
  end

  module Generators
    # Promotes approved AsciiDoc attributes to Jekyll front matter
    class AsciiDocPreprocessor < Generator
      module NoLiquid
        def render_with_liquid?
          false
        end
      end

      AUTO_PAGE_LAYOUT_LINE = %(:page-layout: _auto\n)
      STANDALONE_HEADER = ::Jekyll::Converters::AsciiDocConverter::STANDALONE_HEADER

      def generate(site)
        @converter = (::Jekyll::MIN_VERSION_3 ?
            site.find_converter_instance(::Jekyll::Converters::AsciiDocConverter) :
            site.getConverterImpl(::Jekyll::Converters::AsciiDocConverter)).setup
        unless (@page_attr_prefix = site.config['asciidoc']['page_attribute_prefix']).empty?
          @page_attr_prefix += '-'
        end

        site.pages.each do |page|
          enhance_page(page) if @converter.matches(page.ext)
        end

        (::Jekyll::MIN_VERSION_3 ? site.posts.docs : site.posts).each do |post|
          enhance_page(post, 'posts') if @converter.matches(::Jekyll::MIN_VERSION_3 ? post.data['ext'] : post.ext)
        end
      end

      def enhance_page page, collection = nil
        #collection = (::Jekyll::Document === page ? page.collection.label : nil)
        preamble = page.data.key?('layout') ? '' : AUTO_PAGE_LAYOUT_LINE
        return unless (doc = @converter.load_header(%(#{preamble}#{page.content})))

        page.data['title'] = doc.doctitle if doc.header?
        page.data['author'] = doc.author if doc.author
        page.data['date'] = ::DateTime.parse(doc.revdate).to_time if collection == 'posts' && doc.attr?('revdate')

        page_attr_prefix_l = @page_attr_prefix.length
        unless (adoc_front_matter = doc.attributes
            .select {|name| page_attr_prefix_l == 0 || name.start_with?(@page_attr_prefix) }
            .map {|name, val| %(#{page_attr_prefix_l == 0 ? name : name[page_attr_prefix_l..-1]}: #{val == '' ? '""' : val}) }).empty?
          page.data.update(::SafeYAML.load(adoc_front_matter * %(\n)))
        end

        case page.data['layout']
        when nil
          page.content = %(#{STANDALONE_HEADER}#{page.content}) unless page.data.key?('layout')
        when '', '_auto'
          page.data['layout'] = (collection == 'posts' ? 'post' : 'default')
        when false
          page.data.delete('layout')
          page.content = %(#{STANDALONE_HEADER}#{page.content})
        end

        page.extend(NoLiquid) unless page.data['liquid']
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
      converter = (::Jekyll::MIN_VERSION_3 ?
          site.find_converter_instance(::Jekyll::Converters::AsciiDocConverter) :
          site.getConverterImpl(::Jekyll::Converters::AsciiDocConverter)).setup
      converter.convert(input)
    end
  end
end
