# frozen_string_literal: true

module Basho
  # Hotwire自動入力・カスケードセレクトを提供するRails Engine
  class Engine < ::Rails::Engine
    isolate_namespace Basho

    initializer "basho.importmap", before: "importmap" do |app|
      app.config.importmap.paths << root.join("config/importmap.rb") if app.config.respond_to?(:importmap)
    end

    initializer "basho.assets" do |app|
      app.config.assets.paths << root.join("app/assets/javascripts") if app.config.respond_to?(:assets)
    end
  end
end
