module Jekyll
  module AsciiDoc
    module Utils; extend self
      MessageTopic = 'Jekyll AsciiDoc:'
      NewLine = %(\n)
      StandaloneOptionLine = %([%standalone]#{NewLine})

      def has_front_matter? dlg_method, asciidoc_ext_re, path
        (::File.extname path) =~ asciidoc_ext_re ? true : (dlg_method.call path)
      end

      begin # supports Jekyll >= 2.3.0
        define_method :has_yaml_header?, &(::Jekyll::Utils.method :has_yaml_header?)
      rescue ::NameError; end
    end
  end
end
