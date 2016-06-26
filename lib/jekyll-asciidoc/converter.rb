module Jekyll
  module AsciiDoc
    class Converter < ::Jekyll::Converter
      DefaultAttributes = {
        'idprefix' => '',
        'idseparator' => '-',
        'linkattrs' => '@'
      }
      ImplicitAttributes = {
        'env' => 'site',
        'env-site' => '',
        'site-gen' => 'jekyll',
        'site-gen-jekyll' => '',
        'builder' => 'jekyll',
        'builder-jekyll' => '',
        'jekyll-version' => ::Jekyll::VERSION
      }
      NewLine = Utils::NewLine
      StandaloneOptionLine = Utils::StandaloneOptionLine
      HeaderBoundaryRx = /(?<=\p{Graph})#{NewLine * 2}/

      safe true
      highlighter_prefix NewLine
      highlighter_suffix NewLine

      def initialize(config)
        # NOTE jekyll-watch reinitializes plugins using a shallow clone of config, so no need to reconfigure
        # NOTE check for Configured only works if value of key is defined in _config.yml as Hash
        unless Configured === (asciidoc_config = (config['asciidoc'] ||= {}))
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
          asciidoc_config.extend(Configured)

          begin
            if (dlg_method = Utils.method(:has_yaml_header?)) && asciidoc_config['require_front_matter_header']
              if ::Jekyll::Utils.method(dlg_method.name).arity == -1 # not original method
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

        if (@asciidoc_config = asciidoc_config)['processor'] == 'asciidoctor'
          unless Configured === (@asciidoctor_config = (config['asciidoctor'] ||= {}))
            asciidoctor_config = @asciidoctor_config
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
            attrs = asciidoctor_config[:attributes] = Utils.compile_attributes(
                asciidoctor_config[:attributes], site_attributes.merge(ImplicitAttributes).merge(DefaultAttributes))
            if (imagesdir = attrs['imagesdir']) && !attrs.key?('imagesoutdir') && imagesdir.start_with?('/')
              attrs['imagesoutdir'] = ::File.join(dest, imagesdir)
            end
            asciidoctor_config.extend(Configured)
          end
        end

        @config = config
        @path_info = nil
        @setup = false
      end

      def setup
        return self if @setup
        @setup = true
        case @asciidoc_config['processor']
        when 'asciidoctor'
          begin
            require 'asciidoctor' unless defined?(::Asciidoctor::VERSION)
          rescue ::LoadError
            ::Jekyll.logger.error('jekyll-asciidoc: You are missing a library required to convert AsciiDoc files. Please install using:')
            ::Jekyll.logger.error('', '$ [sudo] gem install asciidoctor')
            ::Jekyll.logger.abort_with('Bailing out; missing required dependency: asciidoctor')
          end
        else
          ::Jekyll.logger.error(%(jekyll-asciidoc: Invalid AsciiDoc processor given: #{@asciidoc_config['processor']}))
          ::Jekyll.logger.error('', 'Valid options are: asciidoctor')
          ::Jekyll.logger.abort_with('Bailing out; invalid Asciidoctor processor')
        end
        self
      end

      def matches(ext)
        ext =~ @asciidoc_config['ext_re']
      end

      def output_ext(ext)
        '.html'
      end

      def before_render(document, payload)
        record_path_info(document) if Document === document
      end

      def after_render(document)
        clear_path_info if Document === document
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
            'outdir' => ::File.dirname(outfile),
            'outpath' => document.url
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
        case @asciidoc_config['processor']
        when 'asciidoctor'
          opts = @asciidoctor_config.merge(parse_header_only: true)
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
          ::Jekyll.logger.warn(%(jekyll-asciidoc: Unknown AsciiDoc processor: #{@asciidoc_config['processor']}. Cannot load document header.))
          doc = nil
        end
        clear_path_info if ::Jekyll::MIN_VERSION_3
        doc
      end

      def convert(content)
        return '' if content.nil? || content.empty?
        setup
        if (standalone = content.start_with?(StandaloneOptionLine))
          content = content[StandaloneOptionLine.length..-1]
        end
        case @asciidoc_config['processor']
        when 'asciidoctor'
          opts = @asciidoctor_config.merge(header_footer: standalone)
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
          ::Jekyll.logger.warn(%(jekyll-asciidoc: Unknown AsciiDoc processor: #{@asciidoc_config['processor']}. Passing through unparsed content.))
          content
        end
      end
    end
  end
end
