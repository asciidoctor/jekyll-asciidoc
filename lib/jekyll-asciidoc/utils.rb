module Jekyll
  module AsciiDoc
    module Utils; extend self
      NewLine = %(\n)
      StandaloneOptionLine = %([%standalone]#{NewLine})
      AttributeReferenceRx = /\\?\{(\w+(?:[\-]\w+)*)\}/

      def has_front_matter? dlg_method, asciidoc_ext_re, path
        (::File.extname path) =~ asciidoc_ext_re ? true : (dlg_method.call path)
      end

      begin # supports Jekyll >= 2.3.0
        define_method :has_yaml_header?, &(::Jekyll::Utils.method :has_yaml_header?)
      rescue ::NameError; end

      def compile_attributes attrs, seed = {}
        if (is_array = ::Array === attrs) || ::Hash === attrs
          attrs.each_with_object seed do |entry, new_attrs|
            key, val = is_array ? ((entry.split '=', 2) + ['', ''])[0..1] : entry
            if key.start_with? '!'
              new_attrs[key[1..-1]] = nil
            elsif key.end_with? '!'
              new_attrs[key.chop] = nil
            else
              new_attrs[key] = val ? (resolve_attribute_refs val, new_attrs) : nil
            end
          end
        else
          seed
        end
      end

      def resolve_attribute_refs text, table
        if text.empty?
          text
        elsif text.include? '{'
          text.gsub AttributeReferenceRx do
            if $&.start_with? '\\'
              $&[1..-1]
            elsif (value = table[$1])
              value
            else
              $&
            end
          end
        else
          text
        end
      end

      def get_converter site
        site.find_converter_instance Converter
      end

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
