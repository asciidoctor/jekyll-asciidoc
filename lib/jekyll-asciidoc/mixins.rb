module Jekyll
  module AsciiDoc
    Configured = ::Module.new
    Document = ::Module.new

    module NoLiquid
      def render_with_liquid?
        false
      end
    end
  end
end
