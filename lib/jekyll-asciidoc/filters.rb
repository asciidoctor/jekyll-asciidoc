module Jekyll
  module AsciiDoc
    module Filters
      # A Liquid filter for converting an AsciiDoc string to HTML.
      #
      # input   - The AsciiDoc String to convert.
      # doctype - The target AsciiDoc doctype (optional, default: nil).
      #
      # Returns the HTML formatted String.
      def asciidocify(input, doctype = nil)
        (@context.registers[:cached_asciidoc_converter] ||= Utils.get_converter(@context.registers[:site]))
          .convert(doctype ? %(:doctype: #{doctype}#{Utils::NewLine}#{input}) : input.to_s)
      end
    end

    ::Liquid::Template.register_filter(Filters)
  end
end
