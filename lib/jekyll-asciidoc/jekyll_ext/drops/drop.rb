class Jekyll::Drops::Drop
  class << self
    # NOTE fixes "warning: instance variable @is_mutable not initialized"
    prepend (Module.new do
      def mutable?
        @is_mutable ||= nil
      end
    end)
  end
end if defined? Jekyll::Drops::Drop
