module Jekyll
  module Converters
    class AsciiDoc < Converter
      safe true

      pygments_prefix "\n"
      pygments_suffix "\n"

      def setup
        return if @setup
        case (@config['asciidoc'] || 'asciidoctor')
          when 'asciidoctor'
            begin
              require 'asciidoctor'
              @config['asciidoc_ext'] ||= 'asciidoc,adoc,ad'
              @config['asciidoctor'] ||= %w(notitle! hardbreaks)
              @setup = true
            rescue LoadError
              STDERR.puts 'You are missing a library required to convert AsciiDoc files. Please run:'
              STDERR.puts '  $ [sudo] gem install asciidoctor'
              raise FatalException.new("Missing dependency: asciidoctor")
            end
          else
            STDERR.puts "Invalid AsciiDoc processor: #{@config['asciidoc']}"
            STDERR.puts "  Valid options are [ asciidoctor ]"
            raise FatalException.new("Invalid AsciiDoc process: #{@config['asciidoc']}")
        end
        @setup = true
      end
      
      def matches(ext)
        rgx = '(' + @config['asciidoc_ext'].gsub(',','|') +')'
        ext =~ Regexp.new(rgx, Regexp::IGNORECASE)
      end

      def output_ext(ext)
        ".html"
      end

      def convert(content)
        setup
        case @config['asciidoc']
        when 'asciidoctor'
          Asciidoctor.render(content, :attributes => @config['asciidoctor'])
        else
          content
        end
      end
    end
  end
end
