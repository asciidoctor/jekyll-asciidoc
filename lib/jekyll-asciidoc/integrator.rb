module Jekyll
  module AsciiDoc
    # Promotes eligible AsciiDoc attributes to page variables and applies page-level settings to all documents handled
    # by the converter included with this plugin. It also copies the custom Pygments stylesheet if Pygments is the
    # source highlighter and configured to use class-based styling.
    class Integrator < ::Jekyll::Generator
      NewLine = Utils::NewLine
      PygmentsRootSelector = /^(.+?)\.pygments +{/

      # Enable plugin when running in safe mode; jekyll-asciidoc gem must also be declared in whitelist
      safe true

      def self.get_instance site
        site.find_generator_instance self
      end

      # This method is triggered each time the site is generated, including after any file has changed when running in
      # watch mode (regardless of incremental setting).
      #
      # @param site [Jekyll::Site] the site being processed.
      #
      # @return [nil] Nothing
      def generate site
        @converter = converter = Converter.get_instance site

        site.pages.select! do |page|
          (converter.matches page.ext) ? (integrate page) : true
        end

        site.collections.each do |name, collection|
          collection.docs.select! do |doc|
            (converter.matches doc.extname) ? (integrate doc, name) : true
          end
        end

        if site.config['asciidoc']['processor'] == 'asciidoctor'
          attrs = site.config['asciidoctor'][:attributes]
          attrs['localdate'], attrs['localtime'] = (site.time.strftime '%Y-%m-%d %H:%M:%S %Z').split ' ', 2
          if ((attrs['source-highlighter'] || '').chomp '@') == 'pygments' &&
              ((attrs['pygments-css'] || '').chomp '@') != 'style' && (attrs.fetch 'pygments-stylesheet', '')
            generate_pygments_stylesheet site, attrs
          end
        end

        nil
      end

      # Integrate the page-related attributes from the AsciiDoc document header into the data Array of the specified
      # {::Jekyll::Page}, {::Jekyll::Post} or {::Jekyll::Document}.
      #
      # @param document [::Jekyll::Page, ::Jekyll::Post, ::Jekyll::Document] the page, post, or document to integrate.
      # @param collection_name [String] the name of the collection to which this document belongs.
      #
      # @return [Boolean] whether the document should be published.
      def integrate document, collection_name = nil
        return true unless (doc = @converter.load_header document)

        data = document.data
        data['asciidoc'] = true
        # NOTE id is already reserved in Jekyll for another purpose, so we'll map id to docid instead
        data['docid'] = doc.id if doc.id
        data['title'] = doc.doctitle if doc.header?
        data['author'] = doc.author if doc.author
        if collection_name && (doc.attr? 'revdate')
          data['date'] = ::Jekyll::Utils.parse_date doc.revdate,
              %(Document '#{document.relative_path}' does not have a valid revdate in the AsciiDoc header.)
        end

        merge_attributes = document.site.config['asciidoctor'][:merge_attributes]

        implicit_vars = document.site.config['asciidoc']['implicit_page_variables']
        implicit_vars = (implicit_vars.split ',').collect(&:strip) if ::String === implicit_vars
        implicit_vars&.each do |implicit_var|
          if doc.attributes.key? implicit_var
            val = ::String === (val = doc.attributes[implicit_var]) ?
                                        (deep_merge merge_attributes[implicit_var], (parse_yaml_value val)) : val
          else
            val = merge_attributes[implicit_var]
          end
          data[implicit_var] = val if val
        end

        page_attr_prefix = document.site.config['asciidoc']['page_attribute_prefix']
        no_prefix = (prefix_size = page_attr_prefix.length) == 0
        adoc_data = doc.attributes.each_with_object({}) do |(key, val), accum|
          if (short_key = shorten key, page_attr_prefix, no_prefix, prefix_size)
            accum[short_key || key] = ::String === val ?
              (deep_merge merge_attributes[key], (parse_yaml_value val)) : val
          end
        end
        merge_attributes.each do |(key, val)|
          if (short_key = shorten key, page_attr_prefix, no_prefix, prefix_size)
            adoc_data[short_key] = val unless adoc_data.key? short_key
          end
        end
        data.update adoc_data unless adoc_data.empty?

        { 'category' => 'categories', 'tag' => 'tags' }.each do |sole_key, coll_key|
          if (sole_val = data[sole_key])
            (coll_val = data[coll_key] ||= []).delete sole_val
            coll_val.unshift sole_val
          elsif (coll_val = data[coll_key])
            data[sole_key] = coll_val[0]
          end
        end

        # NOTE excerpt must be set before layout is assigned since excerpt cannot have a layout (or be standalone)
        unless ::Jekyll::Page === document
          data['excerpt'] = Excerpt.new document, ((excerpt = data['excerpt']) || doc.source)
          data['excerpt_origin'] = excerpt ? ((adoc_data.key? 'excerpt') ? 'asciidoc-header' : 'front-matter') : 'body'
        end

        case data['layout']
        when nil
          data['standalone'] = true unless data.key? 'layout'
        when '', '_auto'
          layout = collection_name ? (collection_name.chomp 's') : 'page'
          data['layout'] = (document.site.layouts.key? layout) ? layout : 'default'
        when false
          data['layout'] = 'none'
          data['standalone'] = true
        end

        document.extend Document
        document.extend NoLiquid unless data['liquid']
        data.fetch 'published', true
      end

      def generate_pygments_stylesheet site, attrs
        css_base = site.source
        unless (css_dir = (attrs['stylesdir'] || '').chomp '@').empty? || (css_dir.start_with? '/')
          css_dir = %(/#{css_dir})
        end
        css_name = attrs['pygments-stylesheet'] || 'asciidoc-pygments.css'
        css_file = ::File.join css_base, css_dir, css_name
        css_style = (attrs['pygments-style'] || 'vs').chomp '@'
        css = ::Asciidoctor::Stylesheets.instance.pygments_stylesheet_data css_style
        # NOTE apply stronger CSS rule for general text color
        css = css.sub PygmentsRootSelector, '\1.pygments, \1.pygments code {'
        if site.static_files.any? {|f| f.path == css_file }
          ::File.write css_file, css unless css == (::File.read css_file)
        else
          ::FileUtils.mkdir_p ::File.dirname css_file
          ::File.write css_file, css
          site.static_files << (::Jekyll::StaticFile.new site, css_base, css_dir, css_name)
        end
      end

      private

      # Parse the specified value as though it is a single-line value part of a YAML key/value pair.
      #
      # Attempt to parse the specified String value as though it is a single-line value part of a YAML key/value pair.
      # If the value fails to parse, wrap the value in single quotes (after escaping any single quotes in the value) and
      # parse it as a character sequence. If the value is empty, return an empty String.
      #
      # @param val [String] the value to parse.
      #
      # @return [Object, String] the value parsed from the string-based YAML value or an empty String if the specified
      # value is empty.
      def parse_yaml_value val
        if val.empty?
          ''
        else
          begin
            ::SafeYAML.load %(--- #{val})
          rescue ::StandardError, ::SyntaxError
            val = val.gsub '\'', '\'\'' if val.include? '\''
            ::SafeYAML.load %(--- \'#{val}\')
          end
        end
      end

      # Simple deep merge implementation that only merges hashes.
      def deep_merge old, new
        return new unless old
        return old unless new

        old.merge new do |_, oldval, newval|
          (::Hash === oldval) && (::Hash === newval) ?
            deep_merge(oldval, newval) : newval
        end
      end

      # Is there a way to make this a closure so only the key is passed?
      def shorten key, prefix, no_prefix, prefix_size
        key if no_prefix
        (key.start_with? prefix) && (key[prefix_size..-1])
      end
    end
  end
end
