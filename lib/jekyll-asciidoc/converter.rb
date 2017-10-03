module Jekyll
  module AsciiDoc
    class Converter < ::Jekyll::Converter
      DefaultAttributes = {
        'idprefix' => '',
        'idseparator' => '-',
        'linkattrs' => '@'
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
        'jekyll-version' => ::Jekyll::VERSION
      }
      MessageTopic = Utils::MessageTopic
      NewLine = Utils::NewLine
      StandaloneOptionLine = %([%standalone]#{NewLine})

      AttributeReferenceRx = /\\?\{(\w+(?:[\-]\w+)*)\}/
      HeaderBoundaryRx = /(?<=\p{Graph})#{NewLine * 2}/

      # Enable plugin when running in safe mode; jekyll-asciidoc gem must also be declared in whitelist
      safe true

      # highlighter prefix/suffix not used by this plugin; defined only to avoid warning
      highlighter_prefix nil
      highlighter_suffix nil

      def initialize config
        @config = config
        @logger = ::Jekyll.logger
        @page_context = {}
        @setup = false

        # NOTE jekyll-watch reinitializes plugins using a shallow clone of config, so no need to reconfigure
        # NOTE check for Configured only works if value of key is defined in _config.yml as Hash
        unless Configured === (asciidoc_config = (config['asciidoc'] ||= {}))
          if ::String === asciidoc_config
            @logger.warn MessageTopic, 'The AsciiDoc configuration should be defined as Hash under asciidoc key instead of as discrete entries.'
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
            page_attr_prefix = old_page_attr_prefix_def ? (old_page_attr_prefix_val || '') :
                ((asciidoc_config.key? 'page_attribute_prefix') ? '' : DefaultPageAttributePrefix)
          end
          asciidoc_config['page_attribute_prefix'] = page_attr_prefix.chomp '-'
          asciidoc_config['require_front_matter_header'] = !!asciidoc_config['require_front_matter_header']
          asciidoc_config.extend Configured

          begin
            if (dlg_method = Utils.method :has_yaml_header?) && asciidoc_config['require_front_matter_header']
              if (::Jekyll::Utils.method dlg_method.name).arity == -1 # not original method
                ::Jekyll::Utils.define_singleton_method dlg_method.name, &dlg_method
              end
            else
              unless (new_method = dlg_method.owner.method :has_front_matter?).respond_to? :curry
                new_method = new_method.to_proc # Ruby < 2.2
              end
              ::Jekyll::Utils.define_singleton_method dlg_method.name, new_method.curry[dlg_method][asciidoc_ext_re]
            end
          rescue ::NameError; end
        end

        if (@asciidoc_config = asciidoc_config)['processor'] == 'asciidoctor'
          unless Configured === (@asciidoctor_config = (config['asciidoctor'] ||= {}))
            asciidoctor_config = @asciidoctor_config
            asciidoctor_config.replace (symbolize_keys asciidoctor_config)
            source = ::File.expand_path config['source']
            dest = ::File.expand_path config['destination']
            case (base = asciidoctor_config[:base_dir])
            when ':source'
              asciidoctor_config[:base_dir] = source
            when ':docdir'
              if defined? ::Jekyll::Hooks
                asciidoctor_config[:base_dir] = :docdir
              else
                @logger.warn MessageTopic, 'Using :docdir as value of base_dir option requires Jekyll 3. Falling back to source directory.'
                asciidoctor_config[:base_dir] = source
              end
            else
              asciidoctor_config[:base_dir] = ::File.expand_path base if base
            end
            asciidoctor_config[:safe] ||= 'safe'
            site_attributes = {
              'site-root' => ::Dir.pwd,
              'site-source' => source,
              'site-destination' => dest,
              'site-baseurl' => config['baseurl'],
              'site-url' => config['url']
            }
            attrs = asciidoctor_config[:attributes] = assemble_attributes asciidoctor_config[:attributes],
                ((site_attributes.merge ImplicitAttributes).merge DefaultAttributes)
            if (imagesdir = attrs['imagesdir']) && !(attrs.key? 'imagesoutdir') && (imagesdir.start_with? '/')
              attrs['imagesoutdir'] = ::File.join dest, (imagesdir.chomp '@')
            end
            asciidoctor_config.extend Configured
          end
        end
      end

      def setup
        return self if @setup
        @setup = true
        case @asciidoc_config['processor']
        when 'asciidoctor'
          begin
            require 'asciidoctor' unless defined? ::Asciidoctor::VERSION
          rescue ::LoadError
            @logger.error MessageTopic, 'You are missing a library required to convert AsciiDoc files. Please install using:'
            @logger.error '', '$ [sudo] gem install asciidoctor'
            @logger.abort_with 'Bailing out; missing required dependency: asciidoctor'
          end
        else
          @logger.error MessageTopic, %(Invalid AsciiDoc processor given: #{@asciidoc_config['processor']})
          @logger.error '', 'Valid options are: asciidoctor'
          @logger.abort_with 'Bailing out; invalid Asciidoctor processor.'
        end
        self
      end

      def self.get_instance site
        site.find_converter_instance self
      end

      def matches ext
        ext =~ @asciidoc_config['ext_re']
      end

      def output_ext ext
        '.html'
      end

      def self.before_render document, payload
        (get_instance document.site).before_render document, payload if Document === document
      end

      def self.after_render document
        (get_instance document.site).after_render document if Document === document
      end

      def before_render document, payload
        # NOTE Jekyll 3.1 incorrectly mapped the page payload to document.data instead of payload['page']
        @page_context[:data] = ::Jekyll::AsciiDoc::Jekyll3_1 ? document.data : payload['page']
        record_paths document
      end

      def after_render document
        @page_context.clear
      end

      def record_paths document, opts = {}
        @page_context[:paths] = paths = {
          'docfile' => (docfile = ::File.join document.site.source, document.relative_path),
          'docdir' => (::File.dirname docfile),
          'docname' => (::File.basename docfile, (::File.extname docfile))
        }
        paths.update({
          'outfile' => (outfile = document.destination document.site.dest),
          'outdir' => (::File.dirname outfile),
          'outpath' => document.url
        }) unless opts[:source_only]
      end

      def clear_paths
        @page_context.delete :paths
      end

      def load_header document
        setup
        record_paths document, source_only: true if defined? ::Jekyll::Hooks
        # NOTE merely an optimization; if this doesn't match, the header still gets isolated by the processor
        header = (document.content.split HeaderBoundaryRx, 2)[0]
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
          # NOTE return instance even if header is empty since attributes may be inherited from config
          doc = ::Asciidoctor.load header, opts
        else
          @logger.warn MessageTopic, %(Unknown AsciiDoc processor: #{@asciidoc_config['processor']}. Cannot load document header.)
          doc = nil
        end
        clear_paths if defined? ::Jekyll::Hooks
        doc
      end

      def convert content
        return '' if content.nil? || content.empty?
        setup
        if (standalone = content.start_with? StandaloneOptionLine)
          content = content[StandaloneOptionLine.length..-1]
        end
        case @asciidoc_config['processor']
        when 'asciidoctor'
          opts = @asciidoctor_config.merge header_footer: standalone
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
          ((@page_context[:data] || {})['document'] = ::Asciidoctor.load content, opts).extend(Liquidable).convert
        else
          @logger.warn MessageTopic, %(Unknown AsciiDoc processor: #{@asciidoc_config['processor']}. Passing through unparsed content.)
          content
        end
      end

      private

      def symbolize_keys hash
        hash.each_with_object({}) {|(key, val), accum| accum[key.to_sym] = val }
      end

      def assemble_attributes attrs, initial = {}
        if (is_array = ::Array === attrs) || ::Hash === attrs
          attrs.each_with_object(initial) {|entry, new_attrs|
            key, val = is_array ? ((entry.split '=', 2) + ['', ''])[0..1] : entry
            if key.start_with? '!'
              new_attrs[key[1..-1]] = nil
            elsif key.end_with? '!'
              new_attrs[key.chop] = nil
            # we're reserving -name to mean "unset implicit value but allow doc to override"
            elsif key.start_with? '-'
              new_attrs.delete key[1..-1]
            else
              new_attrs[key] = if val
                case val
                when ::String
                  resolve_attribute_refs val, new_attrs
                when ::Numeric
                  val.to_s
                when true
                  ''
                else
                  val
                end
              else
                # we may preserve false in the future to mean "unset implicit value but allow doc to override"
                nil
              end
            end
          }
        else
          initial
        end
      end

      def resolve_attribute_refs text, attrs
        if text.empty?
          text
        elsif text.include? '{'
          text.gsub(AttributeReferenceRx) { ($&.start_with? '\\') ? $&[1..-1] : ((attrs.fetch $1, $&).to_s.chomp '@') }
        else
          text
        end
      end

      # Register pre and post render callbacks for saving and clearing contextual AsciiDoc attributes, respectively.
      ::Jekyll::Hooks.tap do |hooks|
        hooks.register [:pages, :documents], :pre_render, &(method :before_render)
        hooks.register [:pages, :documents], :post_render, &(method :after_render)
      end if defined? ::Jekyll::Hooks
    end
  end
end
