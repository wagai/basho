# frozen_string_literal: true

module Basho
  # Hotwire郵便番号自動入力を提供するRails Engine
  class Engine < ::Rails::Engine
    isolate_namespace Basho

    initializer "basho.importmap", before: "importmap" do |app|
      app.config.importmap.paths << root.join("config/importmap.rb") if app.config.respond_to?(:importmap)
    end

    initializer "basho.helpers" do
      ActiveSupport.on_load(:action_view) do
        include Basho::FormHelper
      end
    end

    initializer "basho.assets" do |app|
      app.config.assets.paths << root.join("app/assets/javascripts") if app.config.respond_to?(:assets)
    end

    rake_tasks do
      load File.expand_path("../../tasks/basho.rake", __dir__)
    end
  end
end
