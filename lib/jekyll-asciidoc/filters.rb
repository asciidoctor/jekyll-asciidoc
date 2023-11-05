# frozen_string_literal: true

module Jekyll
  module AsciiDoc
    module Filters
      # A Liquid filter for converting an AsciiDoc string to HTML using {Converter#convert}.
      #
      # @param input [String] the AsciiDoc String to convert.
      # @param doctype [String] the target AsciiDoc doctype.
      #
      # @example Convert the AsciiDoc page excerpt to inline HTML
      #   {{ page.excerpt | asciidocify: 'inline' }}
      #
      # @return [String] the converted result as an HTML-formatted String.
      def asciidocify input, doctype = nil
        (@context.registers[:cached_asciidoc_converter] ||= (Converter.get_instance @context.registers[:site]))
          .convert doctype ? %(:doctype: #{doctype}#{Utils::NewLine}#{input}) : (input || '')
      end

      # A Liquid filter for generating an HTML table of contents from a parsed AsciiDoc document.
      #
      # @param document [Asciidoctor::Document] the parsed AsciiDoc document for which to generate an HTML table of
      # contents.
      # @param levels [Integer] the maximum section depth to use; if not specified, uses the value of toclevels document
      # attribute.
      #
      # @example Generate a table of contents from the document for the current page
      #   {{ page.document | tocify_asciidoc: 3 }}
      #
      # @return [String] the table of contents as an HTML-formatted String.
      def tocify_asciidoc document, levels = nil
        ::Asciidoctor::Document === document ?
          (document.converter.convert document, 'outline', toclevels: (levels.nil_or_empty? ? nil : levels.to_i)) : nil
      end

      # A Liquid filter for accessing docinfo from Asciidoctor.
      #
      # @param document [Asciidoctor::Document] the parsed AsciiDoc document.
      # @param location [Symbol] "head" (default), "header" or "footer" are the standard locations for html.
      #   In the built-in Asciidoctor converter, "head" content is inserted just before the closing </head> tag.
      #   "header" content is inserted just before the default <header> tag (if used), and
      #   "footer" content is inserted just after the default <footer> tag (if used).
      #   In jekyll layouts, you can use any location you want, and insert it anywhere you want.
      #   Consult the Asciidoctor documentation for how to configure the docinfo and docinfodir attributes
      #   so that your docinfo files will be found, and the Asciidoctor extensions documentation for docinfo processors.
      # @param suffix [String] The suffix of the docinfo file(s). If not set, the extension
      #           will be set to the outfilesuffix. (default: nil)
      # @return [String] the docinfo text for the specified location.
      def asciidoc_docinfo document, location = :head, suffix = nil
        ::Asciidoctor::Document === document ?
          (document.docinfo location.to_sym, suffix) : nil
      end
    end

    ::Liquid::Template.register_filter Filters
  end
end
