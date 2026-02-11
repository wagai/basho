# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"

module Basho
  module Generators
    # 既存の +basho_cities+ テーブルに +deprecated_at+ / +successor_code+ を追加するマイグレーションジェネレータ。
    #
    # @example
    #   rails generate basho:upgrade_deprecation
    class UpgradeDeprecationGenerator < Rails::Generators::Base
      include ::ActiveRecord::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      desc "basho_cities テーブルに deprecated_at / successor_code カラムを追加"

      def create_migration_file
        migration_template(
          "add_deprecation_to_basho_cities.rb.erb",
          "db/migrate/add_deprecation_to_basho_cities.rb"
        )
      end
    end
  end
end
