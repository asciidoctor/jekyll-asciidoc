module Jekyll
  module AsciiDoc
    class Converter < ::Jekyll::Converter
      DefaultAttributes = {
        'idprefix' => '',
        'idseparator' => '-',
        'linkattrs' => '@',
      }
      DefaultFileExtensions = %w(asciidoc adoc ad)
      DefaultPageAttributePrefix = 'page'
      ImplicitAttributes = {
        'env' => 'site',
        'env-site' => '',
        'site-gen' => 'jekyll',
        'site-gen-jekyll' => '',
        'builder' => 'jekyll',
        'builder-jekyll' => '',
        'jekyll-version' => ::Jekyll::VERSION,
      }
      MessageTopic = Utils::MessageTopic
      NewLine = Utils::NewLine

      AttributeReferenceRx = /\\?\{(\p{Word}[-\p{Word}]*)\}/
      HeaderBoundaryRx = /(?<=\p{Graph}#{NewLine * 2})/

      # Enable plugin when running in safe mode; jekyll-asciidoc gem must also be declared in whitelist
      safe true

      # highlighter prefix/suffix not used by this plugin; defined only to avoid warning
      highlighter_prefix nil
      highlighter_suffix nil

      def initialize config
        @config = config
        @logger = ::Jekyll.logger
        @page_context = {}

        # NOTE jekyll-watch reinitializes plugins using a shallow clone of config, so no need to reconfigure
        # NOTE check for Configured only works if value of key is defined in _config.yml as Hash
        unless Configured === (asciidoc_config = (config['asciidoc'] ||= {}))
          if ::String === asciidoc_config
            @logger.warn MessageTopic,
                'The AsciiDoc configuration should be defined using Hash on asciidoc key instead of discrete entries.'
            asciidoc_config = config['asciidoc'] = { 'processor' => asciidoc_config }
          else
            asciidoc_config['processor'] ||= 'asciidoctor'
          end
          old_asciidoc_ext = config.delete 'asciidoc_ext'
          asciidoc_ext = (asciidoc_config['ext'] ||= (old_asciidoc_ext || (DefaultFileExtensions * ',')))
          asciidoc_ext_re = asciidoc_config['ext_re'] = /^\.(?:#{asciidoc_ext.tr ',', '|'})$/ix
          old_page_attr_prefix_def = config.key? 'asciidoc_page_attribute_prefix'
          old_page_attr_prefix_val = config.delete 'asciidoc_page_attribute_prefix'
          unless (page_attr_prefix = asciidoc_config['page_attribute_prefix'])
            page_attr_prefix = old_page_attr_prefix_def ? old_page_attr_prefix_val || '' :
                (asciidoc_config.key? 'page_attribute_prefix') ? '' : DefaultPageAttributePrefix
          end
          asciidoc_config['page_attribute_prefix'] = (page_attr_prefix = page_attr_prefix.chomp '-').empty? ?
              '' : %(#{page_attr_prefix}-)
          asciidoc_config['require_front_matter_header'] = !!asciidoc_config['require_front_matter_header']
          asciidoc_config.extend Configured

          if asciidoc_config['require_front_matter_header']
            unless (::Jekyll::Utils.method :has_yaml_header?).owner == ::Jekyll::Utils
              # NOTE restore original method
              ::Jekyll::Utils.extend (::Module.new do
                define_method :has_yaml_header?, &(Utils.method :has_yaml_header?)
              end)
            end
          else
            ::Jekyll::Utils.extend (::Module.new do
              define_method :has_yaml_header?,
                  (Utils.method :has_front_matter?).curry[Utils.method :has_yaml_header?][asciidoc_ext_re]
            end)
          end
        end

        if (@asciidoc_config = asciidoc_config)['processor'] == 'asciidoctor'
          unless Configured === (@asciidoctor_config = (config['asciidoctor'] ||= {}))
            asciidoctor_config = @asciidoctor_config
            asciidoctor_config.replace symbolize_keys asciidoctor_config
            source = ::File.expand_path config['source']
            dest = ::File.expand_path config['destination']
            case (base = asciidoctor_config[:base_dir])
            when ':source'
              asciidoctor_config[:base_dir] = source
            when ':docdir'
              asciidoctor_config[:base_dir] = :docdir
            else
              asciidoctor_config[:base_dir] = ::File.expand_path base if base
            end
            asciidoctor_config[:safe] ||= 'safe'
            site_attributes = {
              'site-root' => ::Dir.pwd,
              'site-source' => source,
              'site-destination' => dest,
              'site-baseurl' => config['baseurl'],
              'site-url' => config['url'],
            }
            attrs = asciidoctor_config[:attributes] = compile_attributes asciidoctor_config[:attributes],
                (compile_attributes asciidoc_config['attributes'],
                    ((site_attributes.merge ImplicitAttributes).merge DefaultAttributes))
            if (imagesdir = attrs['imagesdir']) && !(attrs.key? 'imagesoutdir') && (imagesdir.start_with? '/')
              attrs['imagesoutdir'] = ::File.join dest, (imagesdir.chomp '@')
            end
            asciidoctor_config.extend Configured
          end
        end

        load_processor
      end

      def load_processor
        case @asciidoc_config['processor']
        when 'asciidoctor'
          begin
            require 'asciidoctor' unless defined? ::Asciidoctor::VERSION
          rescue ::LoadError
            @logger.error MessageTopic, 'You\'re missing a library required to convert AsciiDoc files. Install using:'
            @logger.error '', '$ [sudo] gem install asciidoctor'
            @logger.abort_with 'Bailing out; missing required dependency: asciidoctor'
          end
        else
          @logger.error MessageTopic, %(Invalid AsciiDoc processor given: #{@asciidoc_config['processor']})
          @logger.error '', 'Valid options are: asciidoctor'
          @logger.abort_with 'Bailing out; invalid Asciidoctor processor.'
        end
        nil
      end

      def self.get_instance site
        site.find_converter_instance self
      end

      def matches ext
        @asciidoc_config['ext_re'].match? ext
      end

      def output_ext _ext
        '.html'
      end

      def self.before_render document, payload
        (get_instance document.site).before_render document, payload if Document === document
      end

      def self.after_render document
        (get_instance document.site).after_render document if Document === document
      end

      def before_render document, payload
        # NOTE Jekyll 3.1 incorrectly maps the page payload to document.data instead of payload['page']
        @page_context[:data] = ::Jekyll::AsciiDoc::Jekyll3_1 ? document.data : payload['page']
        record_paths document
      end

      def after_render _document
        @page_context.clear
      end

      def record_paths document, opts = {}
        @page_context[:paths] = paths = {
          'docfile' => (docfile = ::File.join document.site.source, document.relative_path),
          'docdir' => (::File.dirname docfile),
          'docname' => (::File.basename docfile, (::File.extname docfile)),
        }
        paths.update(
          'outfile' => (outfile = document.destination document.site.dest),
          'outdir' => (::File.dirname outfile),
          'outpath' => document.url
        ) unless opts[:source_only]
      end

      def clear_paths
        @page_context.delete :paths
      end

      def load_header document
        record_paths document, source_only: true
        # NOTE merely an optimization; if this doesn't match, the header still gets extracted by the processor
        header = (content = document.content) ? (HeaderBoundaryRx =~ content ? $` : content) : ''
        case @asciidoc_config['processor']
        when 'asciidoctor'
          opts = @asciidoctor_config.merge parse_header_only: true
          if (paths = @page_context[:paths])
            if opts[:base_dir] == :docdir
              opts[:base_dir] = paths['docdir'] # NOTE this assignment happens inside the processor anyway
            else
              paths.delete 'docdir'
            end
            opts[:attributes] = opts[:attributes].merge paths
          end
          if (layout_attr = resolve_default_layout document, opts[:attributes])
            opts[:attributes] = opts[:attributes].merge layout_attr
          end
          # NOTE return instance even if header is empty since attributes may be inherited from config
          doc = ::Asciidoctor.load header, opts
        else
          @logger.warn MessageTopic,
              %(Unknown AsciiDoc processor: #{@asciidoc_config['processor']}. Cannot load document header.)
          doc = nil
        end
        clear_paths
        doc
      end

      def convert content
        # NOTE don't use nil_or_empty? since that's only provided only by Asciidoctor
        return '' unless content && !content.empty?

        case @asciidoc_config['processor']
        when 'asciidoctor'
          opts = @asciidoctor_config.merge header_footer: (data = @page_context[:data] || {})['standalone']
          if (paths = @page_context[:paths])
            if opts[:base_dir] == :docdir
              opts[:base_dir] = paths['docdir'] # NOTE this assignment happens inside the processor anyway
            else
              paths.delete 'docdir'
            end
            opts[:attributes] = opts[:attributes].merge paths
          # for auto-extracted excerpt, paths are't available since hooks don't get triggered
          elsif opts[:base_dir] == :docdir
            opts.delete :base_dir
          end
          (data['document'] = ::Asciidoctor.load content, opts).extend(Liquidable).convert
        else
          @logger.warn MessageTopic,
              %(Unknown AsciiDoc processor: #{@asciidoc_config['processor']}. Passing through unparsed content.)
          content
        end
      end

      private

      def symbolize_keys hash
        hash.each_with_object({}) {|(key, val), accum| accum[key.to_sym] = val }
      end

      def compile_attributes attrs, initial = {}
        if (is_array = ::Array === attrs) || ::Hash === attrs
          attrs.each_with_object(initial) do |entry, new_attrs|
            key, val = is_array ? (((entry.split '=', 2) + ['', '']).slice 0, 2) : entry
            if key.start_with? '!'
              new_attrs[key.slice 1, key.length] = nil
            elsif key.end_with? '!'
              new_attrs[key.chop] = nil
            # we're reserving -name to mean "unset implicit value but allow doc to override"
            elsif key.start_with? '-'
              new_attrs.delete key.slice 1, key.length
            else
              case val
              when ::String
                new_attrs[key] = resolve_attribute_refs val, new_attrs
              when ::Numeric
                new_attrs[key] = val.to_s
              when true
                new_attrs[key] = ''
              when nil, false
                # we may preserve false in the future to mean "unset implicit value but allow doc to override"
                # false already has special meaning for page-layout, so don't coerce it
                new_attrs[key] = key == 'page-layout' ? val : nil
              else
                new_attrs[key] = val
              end
            end
          end
        else
          initial
        end
      end

      def resolve_attribute_refs text, attrs
        if text.empty?
          text
        elsif text.include? '{'
          text.gsub AttributeReferenceRx do
            ($&.start_with? '\\') ? ($&.slice 1, $&.length) : ((attrs.fetch $1, $&).to_s.chomp '@')
          end
        else
          text
        end
      end

      def resolve_default_layout document, attributes
        layout_attr_name = %(#{@asciidoc_config['page_attribute_prefix']}layout)
        if attributes.key? layout_attr_name
          if ::String === (layout = attributes[layout_attr_name])
            if layout == '~@'
              layout = 'none@'
            elsif (layout.end_with? '@') && ((document.data.key? 'layout') || document.data['layout'])
              layout = %(#{(layout = document.data['layout']).nil? ? 'none' : layout}@)
            else
              layout = nil
            end
          elsif layout.nil?
            layout = 'none'
          else
            layout = layout.to_s
          end
        elsif (document.data.key? 'layout') || document.data['layout']
          layout = %(#{(layout = document.data['layout']).nil? ? 'none' : layout}@)
        else
          layout = '@'
        end
        layout ? { layout_attr_name => layout } : nil
      end

      # Register pre and post render callbacks for saving and clearing contextual AsciiDoc attributes, respectively.
      ::Jekyll::Hooks.tap do |hooks|
        hooks.register [:pages, :documents], :pre_render, &(method :before_render)
        hooks.register [:pages, :documents], :post_render, &(method :after_render)
      end
    end
  end
end
