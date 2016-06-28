module Jekyll
  module AsciiDoc
    Jekyll3Compatible = (::Gem::Version.new ::Jekyll::VERSION) >= (::Gem::Version.new '3.0.0')
  end
end

module Jekyll
  class Site
    # Backport {::Jekyll::Site#find_converter_instance} to Jekyll 2.
    def find_converter_instance klass
      @converters.find {|candidate| klass === candidate } || raise(%(No Converters found for #{klass}))
    end unless respond_to? :find_converter_instance
  end
end
