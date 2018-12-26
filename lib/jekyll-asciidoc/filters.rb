module Jekyll
  module AsciiDoc
    module Filters
      # A Liquid filter for converting an AsciiDoc string to HTML.
      #
      # input   - The AsciiDoc String to convert.
      # doctype - The target AsciiDoc doctype (optional, default: nil).
      #
      # Examples
      #
      #   {{ page.excerpt | asciidocify: 'inline' }}
      #
      # Returns the converted result as an HTML-formatted String.
      def asciidocify input, doctype = nil
        (@context.registers[:cached_asciidoc_converter] ||= (Converter.get_instance @context.registers[:site]))
          .convert(doctype ? %(:doctype: #{doctype}#{Utils::NewLine}#{input}) : (input || ''))
      end

      # A Liquid filter for generating a table of contents in HTML from a parsed AsciiDoc document.
      #
      # document      - The parsed AsciiDoc document from which to generate a table of contents in HTML.
      # levels        - The max section depth to include (optional, default: value of toclevels document attribute).
      #
      # Examples
      #
      #   {{ page.document | tocify_asciidoc: 3 }}
      #
      # Returns the table of contents as an HTML-formatted String.
      def tocify_asciidoc document, levels = nil
        ::Asciidoctor::Document === document ?
          (document.converter.convert document, 'outline', toclevels: (levels.nil_or_empty? ? nil : levels.to_i)) : nil
      end
    end

    ::Liquid::Template.register_filter Filters
  end
end
