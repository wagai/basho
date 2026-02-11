# frozen_string_literal: true

require "rails"
require "action_controller/railtie"
require "active_record/railtie"
require "basho"
require "basho/engine"

module Dummy
  class Application < Rails::Application
    config.root = File.expand_path("..", __dir__)
    config.eager_load = false
    config.hosts.clear
    config.secret_key_base = "test-secret-key-base-for-dummy-app"
  end
end
