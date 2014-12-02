require File.expand_path("../spawn/version", __FILE__)

module Vx
  module Lib
    module Spawn

      autoload :Process,          File.expand_path("../spawn/process",      __FILE__)
      autoload :SSH,              File.expand_path("../spawn/ssh",          __FILE__)
      autoload :Timeout,          File.expand_path("../spawn/timeout",      __FILE__)
      autoload :ReadTimeout,      File.expand_path("../spawn/read_timeout", __FILE__)
      autoload :TimeoutError,     File.expand_path("../spawn/error",        __FILE__)
      autoload :ReadTimeoutError, File.expand_path("../spawn/error",        __FILE__)

      class << self
        @@pool_interval = 1.0

        def pool_interval
          @@pool_interval
        end

        def pool_interval=(val)
          @@pool_interval = val
        end
      end

      def open_ssh(*args, &block)
        Lib::Spawn::SSH.open(*args, &block)
      end

      def spawn(*args, &block)
        Lib::Spawn::Process.spawn(*args, &block)
      end

    end
  end
end
