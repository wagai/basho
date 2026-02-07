# frozen_string_literal: true

module JpAddress
  class Engine < ::Rails::Engine
    isolate_namespace JpAddress

    initializer "jp_address.importmap", before: "importmap" do |app|
      app.config.importmap.paths << root.join("config/importmap.rb") if app.config.respond_to?(:importmap)
    end

    initializer "jp_address.assets" do |app|
      app.config.assets.paths << root.join("app/assets/javascripts") if app.config.respond_to?(:assets)
    end
  end
end
