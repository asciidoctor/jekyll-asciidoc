module Jekyll
  module AsciiDoc
    class Excerpt < ::Jekyll::Excerpt
      if Jekyll3_0
        def_delegators :@doc, :destination, :url
      else
        def_delegators :@doc, :destination
      end

      def initialize primary_doc, excerpt_content
        excerpt_doc = primary_doc.dup
        excerpt_doc.content = excerpt_content
        excerpt_doc.extend NoLiquid unless primary_doc.data['liquid']
        super excerpt_doc
      end

      def extract_excerpt content
        # NOTE excerpt_doctype has already been resolved from either the page attribute or front matter variable
        if (doctype = (excerpt_data = data)['excerpt_doctype'] ||
            (inherited = doc.site.config['asciidoc']['excerpt_doctype']))
          excerpt_data['doctype'] = doctype
          excerpt_data['excerpt_doctype'] = doc.data['excerpt_doctype'] = doctype if inherited
        end
        content
      end

      def output
        unless defined? @output
          renderer = ::Jekyll::Renderer.new doc.site, self, site.site_payload
          @output = renderer.run
          trigger_hooks :post_render
        end
        @output
      end

      def render_with_liquid?
        !(NoLiquid === doc)
      end

      # NOTE Jekyll 3.0 incorrectly maps to_liquid to primary doc
      alias to_liquid data if Jekyll3_0

      def trigger_hooks hook_name, *args
        #::Jekyll::Hooks.trigger collection.label.to_sym, hook_name, self, *args if collection
        ::Jekyll::Hooks.trigger :documents, hook_name, self, *args
      end
    end
  end
end
