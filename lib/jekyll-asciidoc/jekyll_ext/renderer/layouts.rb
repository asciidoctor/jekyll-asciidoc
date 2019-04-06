module Jekyll
  class Renderer
    # NOTE fixes "warning: instance variable @layouts not initialized"
    prepend (Module.new do
      def layouts
        @layouts = nil unless defined? @layouts
        super
      end
    end)
  end
end if Jekyll::Renderer.method_defined? :layouts
