module Jekyll
  module AsciiDoc
    Jekyll3Compatible = (::Gem::Version.new ::Jekyll::VERSION) >= (::Gem::Version.new '3.0.0')
  end
end

module Jekyll
  class Site
    # Backport {::Jekyll::Site#find_converter_instance} to Jekyll 2.
    def find_converter_instance type
      converters.find {|candidate| type === candidate } || (raise %(No Converters found for #{type}))
    end unless respond_to? :find_converter_instance

    # Introduce complement to {::Jekyll::Site#find_converter_instance} for generators.
    def find_generator_instance type
      generators.find {|candidate| type === candidate } || (raise %(No Generators found for #{type}))
    end unless respond_to? :find_generator_instance
  end
end
