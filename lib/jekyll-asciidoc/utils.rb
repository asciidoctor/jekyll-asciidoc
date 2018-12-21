module Jekyll
  module AsciiDoc
    module Utils; extend self
      MessageTopic = 'Jekyll AsciiDoc:'
      NewLine = %(\n)

      def has_front_matter? dlg_method, asciidoc_ext_re, path
        (asciidoc_ext_re.match? ::File.extname path) || (dlg_method.call path)
      end

      # NOTE use define_method to match signature of original method (and avoid extra call)
      define_method :has_yaml_header?, &(::Jekyll::Utils.method :has_yaml_header?)
    end
  end
end
