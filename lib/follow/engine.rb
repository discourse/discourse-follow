# frozen_string_literal: true

module ::Follow
  class Engine < ::Rails::Engine
    engine_name "follow"
    isolate_namespace Follow
    config.autoload_paths << File.join(config.root, "lib")
  end
end
