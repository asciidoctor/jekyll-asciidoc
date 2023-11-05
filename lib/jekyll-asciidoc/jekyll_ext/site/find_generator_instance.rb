# frozen_string_literal: true

module Jekyll
  class Site
    # Introduce complement to {::Jekyll::Site#find_converter_instance} for generators.
    def find_generator_instance type
      generators.find {|candidate| type === candidate } || (raise %(No Generators found for #{type}))
    end
  end
end unless Jekyll::Site.method_defined? :find_generator_instance
