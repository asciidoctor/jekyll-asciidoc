module Jekyll
  module AsciiDoc
    # Promotes eligible AsciiDoc attributes to page variables and applies page-level settings to all documents handled
    # by the converter included with this plugin. It also copies the custom Pygments stylesheet if Pygments is the
    # source highlighter and configured to use class-based styling.
    class Integrator < ::Jekyll::Generator
      NewLine = Utils::NewLine
      StandaloneOptionLine = Converter::StandaloneOptionLine

      # Enable plugin when running in safe mode; jekyll-asciidoc gem must also be declared in whitelist
      safe true

      def self.get_instance site
        site.find_generator_instance self
      end

      # This method is triggered each time the site is generated, including after any file has changed when running in
      # watch mode (regardless of incremental setting).
      def generate site
        @converter = converter = (Converter.get_instance site).setup

        unless (@page_attr_prefix = site.config['asciidoc']['page_attribute_prefix']).empty?
          @page_attr_prefix = %(#{@page_attr_prefix}-)
        end

        site.pages.select! do |page|
          (converter.matches page.ext) ? (integrate page) : true
        end

        # NOTE posts were migrated to a collection named 'posts' in Jekyll 3
        site.posts.select! do |post|
          (converter.matches post.ext) ? (integrate post, 'posts') : true
        end if site.respond_to? :posts=

        site.collections.each do |name, collection|
          next unless collection.write?
          collection.docs.select! do |doc|
            (converter.matches doc.extname) ? (integrate doc, name) : true
          end
        end

        attrs = site.config['asciidoctor'][:attributes]
        attrs['localdate'], attrs['localtime'] = (site.time.strftime '%Y-%m-%d %H:%M:%S %Z').split ' ', 2
        if ((attrs['source-highlighter'] || '').chomp '@') == 'pygments' &&
            ((attrs['pygments-css'] || '').chomp '@') != 'style' && (attrs.fetch 'pygments-stylesheet', '')
          generate_pygments_stylesheet site, attrs
        end
      end

      # Integrate the page-related attributes from the AsciiDoc document header into the data Array of the specified
      # {::Jekyll::Page}, {::Jekyll::Post} or {::Jekyll::Document}.
      #
      # document        - the Page, Post or Document instance to integrate.
      # collection_name - the String name of the collection to which this document belongs (optional, default: nil).
      #
      # Returns a [Boolean] indicating whether the document should be published.
      def integrate document, collection_name = nil
        data = document.data
        document.content = [%(:#{@page_attr_prefix}layout: _auto), document.content] * NewLine unless data.key? 'layout'
        return true unless (doc = @converter.load_header document)

        # NOTE id is already reserved in Jekyll for another purpose, so we'll map id to docid instead
        data['docid'] = doc.id if doc.id
        data['title'] = doc.doctitle if doc.header?
        data['author'] = doc.author if doc.author
        if collection_name == 'posts' && (doc.attr? 'revdate')
          data['date'] = ::Jekyll::Utils.parse_date doc.revdate,
              %(Document '#{document.relative_path}' does not have a valid revdate in the AsciiDoc header.)
          # NOTE Jekyll 2.3 requires date field to be set explicitly
          document.date = data['date'] if document.respond_to? :date=
        end

        no_prefix = (prefix_size = @page_attr_prefix.length) == 0
        unless (adoc_data = doc.attributes.each_with_object({}) {|(key, val), accum|
              if no_prefix || ((key.start_with? @page_attr_prefix) && key = key[prefix_size..-1])
                accum[key] = ::String === val ? (parse_yaml_value val) : val
              end
            }).empty?
          data.update adoc_data
        end

        { 'category' => 'categories', 'tag' => 'tags' }.each do |sole_key, coll_key|
          if (sole_val = data.delete sole_key) &&
              !((coll_val = (data[coll_key] ||= [])).include? sole_val)
            coll_val << sole_val 
          end
        end

        case data['layout']
        when nil
          document.content = %(#{StandaloneOptionLine}#{document.content}) unless data.key? 'layout'
        when '', '_auto'
          layout = collection_name ? (collection_name.chomp 's') : 'page'
          data['layout'] = (document.site.layouts.key? layout) ? layout : 'default'
        when false
          data.delete 'layout'
          document.content = %(#{StandaloneOptionLine}#{document.content})
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
        if (css_name = attrs['pygments-stylesheet']).nil_or_empty?
          css_name = 'asciidoc-pygments.css'
        end
        css_file = ::File.join css_base, css_dir, css_name
        css_style = (attrs['pygments-style'] || 'vs').chomp '@'
        css = ::Asciidoctor::Stylesheets.instance.pygments_stylesheet_data css_style
        # NOTE apply stronger CSS rule for general text color
        css = css.sub '.listingblock .pygments  {', '.listingblock .pygments, .listingblock .pygments code {'
        if site.static_files.any? {|f| f.path == css_file }
          ::IO.write css_file, css unless css == (::IO.read css_file)
        else
          ::Asciidoctor::Helpers.mkdir_p (::File.dirname css_file)
          ::IO.write css_file, css
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
      # val - The String value to parse.
      #
      # Returns an [Object] parsed from the string-based YAML value or empty [String] if the specified value is empty.
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
    end
  end
end
