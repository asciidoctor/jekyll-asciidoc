module Jekyll
  module AsciiDoc
    # Registers before and after render hooks to set contextual attributes,
    # promotes eligible AsciiDoc attributes to page variables, and applies
    # certain page-level settings.
    class Integrator < ::Jekyll::Generator
      NewLine = Utils::NewLine
      StandaloneOptionLine = Utils::StandaloneOptionLine

      # Enable plugin when running in safe mode
      # jekyll-asciidoc gem must also be declared in whitelist
      safe true

      def generate site
        @converter = converter = (Utils.get_converter site).setup

        if ::Jekyll::MIN_VERSION_3
          before_render_callback = converter.method :before_render
          after_render_callback = converter.method :after_render
          [:pages, :documents].each do |collection_name|
            ::Jekyll::Hooks.register collection_name, :pre_render, &before_render_callback
            ::Jekyll::Hooks.register collection_name, :post_render, &after_render_callback
          end
        end

        unless (@page_attr_prefix = site.config['asciidoc']['page_attribute_prefix']).empty?
          @page_attr_prefix = %(#{@page_attr_prefix}-)
        end

        site.pages.select! do |page|
          (converter.matches page.ext) ? (integrate page) : true
        end

        # NOTE posts were migrated to a collection named 'posts' in Jekyll 3
        site.posts.select! do |post|
          (converter.matches post.ext) ? (integrate post, 'posts') : true
        end unless ::Jekyll::MIN_VERSION_3

        site.collections.each do |name, collection|
          next unless collection.write?
          collection.docs.select! do |doc|
            ((converter.matches ::Jekyll::MIN_VERSION_3) ? doc.data['ext'] : doc.extname) ? (integrate doc, name) : true
          end
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

        len = @page_attr_prefix.length
        unless (adoc_front_matter = doc.attributes
            .select {|name| len.zero? || (name.start_with? @page_attr_prefix) }
            .map {|name, val| %(#{len.zero? ? name : name[len..-1]}: #{Utils.prepare_yaml_value val}) })
            .empty?
          document.data.update(::SafeYAML.load adoc_front_matter * NewLine)
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
    end
  end
end
