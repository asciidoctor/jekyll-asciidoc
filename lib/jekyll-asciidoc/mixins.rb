module Jekyll
  module AsciiDoc
    Configured = ::Module.new
    Document = ::Module.new

    module Liquidable
      def to_liquid
        self
      end
    end

    module NoLiquid
      def render_with_liquid?
        false
      end
    end
  end
end
