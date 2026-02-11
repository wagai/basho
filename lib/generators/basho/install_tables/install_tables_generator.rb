# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"

module Basho
  module Generators
    class InstallTablesGenerator < Rails::Generators::Base
      include ::ActiveRecord::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      desc "basho_prefectures / basho_cities テーブルのマイグレーションを生成"

      def create_migration_files
        migration_template "create_basho_prefectures.rb.erb", "db/migrate/create_basho_prefectures.rb"
        migration_template "create_basho_cities.rb.erb", "db/migrate/create_basho_cities.rb"
      end
    end
  end
end
