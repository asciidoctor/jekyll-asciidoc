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
