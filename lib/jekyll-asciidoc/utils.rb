# frozen_string_literal: true

module Jekyll
  module AsciiDoc
    module Utils
      MessageTopic = 'Jekyll AsciiDoc:'
      NewLine = ?\n

      module_function

      # Checks whether the file at the specified path has front matter. For AsciiDoc files, this method always returns
      # true. Otherwise, it delegates to {::Jekyll::Utils.has_yaml_header?}.
      #
      # @param dlg_method [Method] the delegate method to call if this path is not an AsciiDoc file.
      # @param asciidoc_ext_rx [Regexp] the regular expression to use to check if this path is an AsciiDoc file.
      # @param path [String] the path to check.
      #
      # @return [Boolean] whether the file at this path has front matter.
      def has_front_matter? dlg_method, asciidoc_ext_rx, path
        (asciidoc_ext_rx.match? ::File.extname path) || (dlg_method.call path)
      end

      # NOTE use define_method to match signature of original method (and avoid extra call)
      define_method :has_yaml_header?, &(::Jekyll::Utils.method :has_yaml_header?)
    end
  end
end
