module Jekyll
  MIN_VERSION_3 = ::Gem::Version.new(VERSION) >= ::Gem::Version.new('3.0.0') unless defined?(MIN_VERSION_3)

  module AsciiDoc
    module Configured; end
    module Document; end
    module Utils
      extend self

      AttributeReferenceRx = /\\?\{(\w+(?:[\-]\w+)*)\}/

      def has_front_matter?(dlg_method, asciidoc_ext_re, path)
        ::File.extname(path) =~ asciidoc_ext_re ? true : dlg_method.call(path)
      end

      begin # supports Jekyll >= 2.3.0
        define_method(:has_yaml_header?, &::Jekyll::Utils.method(:has_yaml_header?))
      rescue ::NameError; end

      def compile_attributes(attrs, seed = {})
        if (is_array = ::Array === attrs) || ::Hash === attrs
          attrs.each_with_object(seed) {|entry, new_attrs|
            key, val = is_array ? (entry.split('=', 2) + ['', ''])[0..1] : entry
            if key.start_with?('!')
              new_attrs[key[1..-1]] = nil
            elsif key.end_with?('!')
              new_attrs[key.chop] = nil
            elsif val
              new_attrs[key] = resolve_attribute_refs(val, new_attrs)
            else
              new_attrs[key] = nil
            end
          }
        else
          seed
        end
      end

      def resolve_attribute_refs text, table
        if text.empty?
          text
        elsif text.include?('{')
          text.gsub(AttributeReferenceRx) {
            if $&.start_with?('\\')
              $&[1..-1]
            elsif (value = table[$1])
              value
            else
              $&
            end
          }
        else
          text
        end
      end

      if ::Jekyll::MIN_VERSION_3
        def get_converter(site)
          site.find_converter_instance(::Jekyll::Converters::AsciiDocConverter)
        end
      else
        def get_converter(site)
          site.getConverterImpl(::Jekyll::Converters::AsciiDocConverter)
        end
      end

      def prepare_yaml_value val
        if ::String === val
          if val.empty?
            '\'\''
          else
            begin
              ::SafeYAML.load(%(--- #{val}))
              val
            rescue
              val.include?('\'') ? %(\'#{val.gsub('\'', '\'\'')}\') : %(\'#{val}\')
            end
          end
        else
          val
        end
      end
    end
  end

  module Converters
    class AsciiDocConverter < Converter
      DEFAULT_ATTRIBUTES = {
        'idprefix' => '',
        'idseparator' => '-',
        'linkattrs' => '@'
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
      STANDALONE_OPTION_LINE = %([%standalone]\n)
      HeaderBoundaryRx = /(?<=\p{Graph})\n\n/

      safe true
      highlighter_prefix %(\n)
      highlighter_suffix %(\n)

      def initialize(config)
        # NOTE jekyll-watch reinitializes plugins using a shallow clone of config, so no need to reconfigure
        # NOTE check for Configured only works if value of key is defined in _config.yml as Hash
        unless ::Jekyll::AsciiDoc::Configured === (asciidoc_config = (config['asciidoc'] ||= {}))
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
                (asciidoc_config.key?('page_attribute_prefix') ? '' : 'page')
          end
          asciidoc_config['page_attribute_prefix'] = page_attr_prefix.chomp('-')
          asciidoc_config['require_front_matter_header'] = !!asciidoc_config['require_front_matter_header']
          asciidoc_config.extend(::Jekyll::AsciiDoc::Configured)

          begin
            dlg_method = ::Jekyll::AsciiDoc::Utils.method(:has_yaml_header?)
            if asciidoc_config['require_front_matter_header']
              if ::Jekyll::Utils.method(dlg_method.name).arity == -1 # not the original method
                ::Jekyll::Utils.define_singleton_method(dlg_method.name, &dlg_method)
              end
            else
              unless (new_method = dlg_method.owner.method(:has_front_matter?)).respond_to?(:curry)
                new_method = new_method.to_proc # Ruby < 2.2
              end
              ::Jekyll::Utils.define_singleton_method(dlg_method.name, new_method.curry[dlg_method][asciidoc_ext_re])
            end
          rescue ::NameError; end
        end

        unless ::Jekyll::AsciiDoc::Configured === (asciidoctor_config = (config['asciidoctor'] ||= {}))
          asciidoctor_config.replace(asciidoctor_config.each_with_object({}) {|(k, v), h| h[k.to_sym] = v })
          source = ::File.expand_path(config['source'])
          dest = ::File.expand_path(config['destination'])
          case (base = asciidoctor_config[:base_dir])
          when ':source'
            asciidoctor_config[:base_dir] = source
          when ':docdir'
            if ::Jekyll::MIN_VERSION_3
              asciidoctor_config[:base_dir] = :docdir
            else
              ::Jekyll.logger.warn('jekyll-asciidoc: Using :docdir as value of base_dir option requires Jekyll 3. Falling back to source directory.')
              asciidoctor_config[:base_dir] = source
            end
          else
            asciidoctor_config[:base_dir] = ::File.expand_path(base) if base
          end
          asciidoctor_config[:safe] ||= 'safe'
          site_attributes = {
            'site-root' => ::Dir.pwd,
            'site-source' => source,
            'site-destination' => dest,
            'site-baseurl' => config['baseurl'],
            'site-url' => config['url']
          }
          attrs = asciidoctor_config[:attributes] = ::Jekyll::AsciiDoc::Utils.compile_attributes(
              asciidoctor_config[:attributes], site_attributes.merge(IMPLICIT_ATTRIBUTES).merge(DEFAULT_ATTRIBUTES))
          if (imagesdir = attrs['imagesdir']) && !attrs.key?('imagesoutdir') && imagesdir.start_with?('/')
            attrs['imagesoutdir'] = ::File.join(dest, imagesdir)
          end
          asciidoctor_config.extend(::Jekyll::AsciiDoc::Configured)
        end

        @config = config
        @path_info = nil
        @setup = false
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

      def before_render(document, payload)
        record_path_info(document) if ::Jekyll::AsciiDoc::Document === document
      end

      def after_render(document)
        clear_path_info if ::Jekyll::AsciiDoc::Document === document
      end

      def record_path_info(document, opts = {})
        @path_info = {
          'docfile' => (docfile = ::File.join(document.site.source, document.relative_path)),
          'docdir' => ::File.dirname(docfile),
          'docname' => ::File.basename(docfile, ::File.extname(docfile))
        }
        unless opts[:source_only]
          @path_info.update({
            'outfile' => (outfile = document.destination(document.site.dest)),
            'outdir' => ::File.dirname(outfile)
          })
        end
      end

      def clear_path_info
        @path_info = nil
      end

      def load_header(document)
        setup
        record_path_info(document, source_only: true) if ::Jekyll::MIN_VERSION_3
        # NOTE merely an optimization; if this doesn't match, the header still gets isolated by the processor
        header = document.content.split(HeaderBoundaryRx, 2)[0]
        case @config['asciidoc']['processor']
        when 'asciidoctor'
          opts = @config['asciidoctor'].merge(parse_header_only: true)
          if @path_info
            if opts[:base_dir] == :docdir
              opts[:base_dir] = @path_info['docdir'] # NOTE this assignment happens inside the processor anyway
            else
              @path_info.delete('docdir')
            end
            opts[:attributes] = opts[:attributes].merge(@path_info)
          end
          # NOTE return instance even if header is empty since attributes may be inherited from config
          doc = ::Asciidoctor.load(header, opts)
        else
          ::Jekyll.logger.warn(%(jekyll-asciidoc: Unknown AsciiDoc processor: #{@config['asciidoc']['processor']}. Cannot load document header.))
          doc = nil
        end
        clear_path_info if ::Jekyll::MIN_VERSION_3
        doc
      end

      def convert(content)
        return '' if content.nil? || content.empty?
        setup
        if (standalone = content.start_with?(STANDALONE_OPTION_LINE))
          content = content[STANDALONE_OPTION_LINE.length..-1]
        end
        case @config['asciidoc']['processor']
        when 'asciidoctor'
          opts = @config['asciidoctor'].merge(header_footer: standalone)
          if @path_info
            if opts[:base_dir] == :docdir
              opts[:base_dir] = @path_info['docdir'] # NOTE this assignment happens inside the processor anyway
            else
              @path_info.delete('docdir')
            end
            opts[:attributes] = opts[:attributes].merge(@path_info)
          end
          ::Asciidoctor.convert(content, opts)
        else
          ::Jekyll.logger.warn(%(jekyll-asciidoc: Unknown AsciiDoc processor: #{@config['asciidoc']['processor']}. Passing through unparsed content.))
          content
        end
      end
    end
  end

  module Generators
    # Promotes eligible AsciiDoc attributes to page variables and applies certain page-level settings.
    class AsciiDocHeaderIntegrator < Generator
      module NoLiquid
        def render_with_liquid?
          false
        end
      end

      STANDALONE_OPTION_LINE = ::Jekyll::Converters::AsciiDocConverter::STANDALONE_OPTION_LINE

      def generate(site)
        @converter = converter = ::Jekyll::AsciiDoc::Utils.get_converter(site).setup

        if ::Jekyll::MIN_VERSION_3
          before_render_callback = converter.method(:before_render)
          after_render_callback = converter.method(:after_render)
          [:pages, :documents].each do |collection_name|
            ::Jekyll::Hooks.register(collection_name, :pre_render, &before_render_callback)
            ::Jekyll::Hooks.register(collection_name, :post_render, &after_render_callback)
          end
        end

        unless (@page_attr_prefix = site.config['asciidoc']['page_attribute_prefix']).empty?
          @page_attr_prefix += '-'
        end

        site.pages.select! do |page|
          converter.matches(page.ext) ? enhance(page) : true
        end

        # NOTE posts were migrated to a collection named 'posts' in Jekyll 3
        site.posts.select! do |post|
          converter.matches(post.ext) ? enhance(post, 'posts') : true
        end unless ::Jekyll::MIN_VERSION_3

        site.collections.each do |name, collection|
          next unless collection.write?
          collection.docs.select! do |doc|
            converter.matches(::Jekyll::MIN_VERSION_3 ? doc.data['ext'] : doc.extname) ? enhance(doc, name) : true
          end
        end
      end

      # Integrate the page-related attributes from the AsciiDoc document header
      # into the data Array of the specified {::Jekyll::Page}, {::Jekyll::Post}
      # or {::Jekyll::Document}.
      #
      # document        - the Page, Post or Document instance to enhance.
      # collection_name - the String name of the collection to which this
      #                   document belongs (optional, default: nil).
      #
      # Returns a [Boolean] indicating whether the document should be published.
      def enhance document, collection_name = nil
        document.extend(::Jekyll::AsciiDoc::Document)
        document.content = %(:#{@page_attr_prefix}layout: _auto\n#{document.content}) unless document.data.key?('layout')
        return unless (doc = @converter.load_header(document))

        document.data['title'] = doc.doctitle if doc.header?
        document.data['author'] = doc.author if doc.author
        document.data['date'] = ::DateTime.parse(doc.revdate).to_time if collection_name == 'posts' && doc.attr?('revdate')

        len = @page_attr_prefix.length
        unless (adoc_front_matter = doc.attributes
            .select {|name| len.zero? || name.start_with?(@page_attr_prefix) }
            .map {|name, val|
                %(#{len.zero? ? name : name[len..-1]}: #{::Jekyll::AsciiDoc::Utils.prepare_yaml_value(val)})
            }).empty?
          document.data.update(::SafeYAML.load(adoc_front_matter * %(\n)))
        end

        case document.data['layout']
        when nil
          document.content = %(#{STANDALONE_OPTION_LINE}#{document.content}) unless document.data.key?('layout')
        when '', '_auto'
          layout = collection_name ? collection_name.chomp('s') : 'page'
          document.data['layout'] = document.site.layouts.key?(layout) ? layout : 'default'
        when false
          document.data.delete('layout')
          document.content = %(#{STANDALONE_OPTION_LINE}#{document.content})
        end

        document.extend(NoLiquid) unless document.data['liquid']
        document.data.fetch('published', true)
      end
    end
  end

  module Filters
    # Convert an AsciiDoc string into HTML output.
    #
    # input   - The AsciiDoc String to convert.
    # doctype - The target AsciiDoc doctype (optional, default: nil).
    #
    # Returns the HTML formatted String.
    def asciidocify(input, doctype = nil)
      (@context.registers[:cached_asciidoc_converter] ||=
          ::Jekyll::AsciiDoc::Utils.get_converter(@context.registers[:site]))
        .convert(doctype ? %(:doctype: #{doctype}\n#{input}) : input.to_s)
    end
  end
end
