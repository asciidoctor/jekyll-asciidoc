module Jekyll
  module AsciiDoc
    Jekyll3Compatible = (jekyll_version = ::Gem::Version.new ::Jekyll::VERSION) >= (::Gem::Version.new '3.0.0')
    Jekyll3_1 = (::Gem::Requirement.new '~> 3.1.0').satisfied_by? jekyll_version
  end
end

module Jekyll
  class Site
    # Backport {::Jekyll::Site#find_converter_instance} to Jekyll 2.
    def find_converter_instance type
      converters.find {|candidate| type === candidate } || (raise %(No Converters found for #{type}))
    end unless method_defined? :find_converter_instance

    # Introduce complement to {::Jekyll::Site#find_converter_instance} for generators.
    def find_generator_instance type
      generators.find {|candidate| type === candidate } || (raise %(No Generators found for #{type}))
    end unless method_defined? :find_generator_instance
  end
end
