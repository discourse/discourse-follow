# frozen_string_literal: true
module ::Follow
  class Engine < ::Rails::Engine
    engine_name "follow"
    isolate_namespace Follow
  end
end
