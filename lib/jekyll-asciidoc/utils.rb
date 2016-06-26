module Jekyll
  module AsciiDoc
    module Utils; extend self
      NewLine = %(\n)
      StandaloneOptionLine = %([%standalone]#{NewLine})
      AttributeReferenceRx = /\\?\{(\w+(?:[\-]\w+)*)\}/

      def has_front_matter?(dlg_method, asciidoc_ext_re, path)
        ::File.extname(path) =~ asciidoc_ext_re ? true : dlg_method.call(path)
      end

      begin # supports Jekyll >= 2.3.0
        define_method(:has_yaml_header?, &::Jekyll::Utils.method(:has_yaml_header?))
      rescue ::NameError; end

      def compile_attributes(attrs, seed = {})
        if (is_array = ::Array === attrs) || ::Hash === attrs
          attrs.each_with_object(seed) {|entry, new_attrs|
            key, val = is_array ? (entry.split('=', 2) + ['', ''])[0..1] : entry
            if key.start_with?('!')
              new_attrs[key[1..-1]] = nil
            elsif key.end_with?('!')
              new_attrs[key.chop] = nil
            elsif val
              new_attrs[key] = resolve_attribute_refs(val, new_attrs)
            else
              new_attrs[key] = nil
            end
          }
        else
          seed
        end
      end

      def resolve_attribute_refs text, table
        if text.empty?
          text
        elsif text.include?('{')
          text.gsub(AttributeReferenceRx) {
            if $&.start_with?('\\')
              $&[1..-1]
            elsif (value = table[$1])
              value
            else
              $&
            end
          }
        else
          text
        end
      end

      if ::Jekyll::MIN_VERSION_3
        def get_converter(site)
          site.find_converter_instance(Converter)
        end
      else
        def get_converter(site)
          site.getConverterImpl(Converter)
        end
      end

      def prepare_yaml_value val
        return val unless ::String === val
        if val.empty?
          '\'\''
        else
          begin
            ::SafeYAML.load(%(--- #{val}))
            val
          rescue
            val.include?('\'') ? %(\'#{val.gsub('\'', '\'\'')}\') : %(\'#{val}\')
          end
        end
      end
    end
  end
end
