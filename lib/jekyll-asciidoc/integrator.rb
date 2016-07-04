module Jekyll
  module AsciiDoc
    # Registers before and after render hooks to set contextual attributes,
    # promotes eligible AsciiDoc attributes to page variables, and applies
    # certain page-level settings.
    class Integrator < ::Jekyll::Generator
      NewLine = Utils::NewLine
      StandaloneOptionLine = Converter::StandaloneOptionLine

      # Enable plugin when running in safe mode
      # jekyll-asciidoc gem must also be declared in whitelist
      safe true

      def self.get_instance site
        site.find_generator_instance self
      end

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

        if (attrs = site.config['asciidoctor'][:attributes]) &&
            ((attrs['source-highlighter'] || '').chomp '@') == 'pygments' &&
            ((attrs['pygments-css'] || '').chomp '@') != 'style' && (attrs.fetch 'pygments-stylesheet', '')
          generate_pygments_stylesheet site, attrs
        end
      end

      # Integrate the page-related attributes from the AsciiDoc document header
      # into the data Array of the specified {::Jekyll::Page}, {::Jekyll::Post}
      # or {::Jekyll::Document}.
      #
      # document        - the Page, Post or Document instance to integrate.
      # collection_name - the String name of the collection to which this
      #                   document belongs (optional, default: nil).
      #
      # Returns a [Boolean] indicating whether the document should be published.
      def integrate document, collection_name = nil
        document.extend Document
        document.content = [%(:#{@page_attr_prefix}layout: _auto), document.content] * NewLine unless document.data.key? 'layout'
        return unless (doc = @converter.load_header document)

        document.data['title'] = doc.doctitle if doc.header?
        document.data['author'] = doc.author if doc.author
        document.data['date'] = (::DateTime.parse doc.revdate).to_time if collection_name == 'posts' && (doc.attr? 'revdate')

        no_prefix = (prefix_size = @page_attr_prefix.length).zero?
        unless (adoc_header_data = doc.attributes
            .each_with_object({}) {|(key, val), accum|
              if no_prefix || ((key.start_with? @page_attr_prefix) && key = key[prefix_size..-1])
                accum[key] = ::String === val ? (parse_yaml_value val) : val
              end
            }).empty?
          document.data.update adoc_header_data
        end

        case document.data['layout']
        when nil
          document.content = %(#{StandaloneOptionLine}#{document.content}) unless document.data.key? 'layout'
        when '', '_auto'
          layout = collection_name ? (collection_name.chomp 's') : 'page'
          document.data['layout'] = (document.site.layouts.key? layout) ? layout : 'default'
        when false
          document.data.delete 'layout'
          document.content = %(#{StandaloneOptionLine}#{document.content})
        end

        document.extend NoLiquid unless document.data['liquid']
        document.data.fetch 'published', true
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

      # Parse the specified value as though it is a single-line value part of a
      # YAML key/value pair.
      #
      # Attempt to parse the specified String value as though it is a
      # single-line value part of a YAML key/value pair. If the value fails to
      # parse, wrap the value in single quotes (after escaping any single
      # quotes in the value) and parse it as a character sequence. If the value
      # is empty, return an empty String.
      #
      # val - The String value to parse.
      #
      # Returns an [Object] parsed from the string-based YAML value or empty
      # [String] if the specified value is empty.
      def parse_yaml_value val
        if val.empty?
          ''
        else
          begin
            ::SafeYAML.load %(--- #{val})
          rescue
            val = val.gsub '\'', '\'\'' if val.include? '\''
            ::SafeYAML.load %(--- \'#{val}\')
          end
        end
      end
    end
  end
end
