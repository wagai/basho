# frozen_string_literal: true

require_relative "postal_auto_resolve"

module Basho
  module ActiveRecord
    # ActiveRecordモデルにbasho / basho_postalマクロを提供する
    module Base
      def basho(column)
        column_name = column.to_s

        define_method(:city) { (c = send(column_name)) && Basho::City.find(c) }
        define_method(:prefecture) { city&.prefecture }
        define_method(:full_address) do
          pref = prefecture
          cty = city
          "#{pref.name}#{cty.name}" if pref && cty
        end
      end

      def basho_postal(column, **mappings)
        column_name = column.to_s

        define_method(:postal_address) do
          code = send(column_name)
          return nil unless code

          postal = Basho::PostalCode.find(code).first
          return nil unless postal

          "#{postal.prefecture_name}#{postal.city_name}#{postal.town}"
        end

        PostalAutoResolve.install(self, column_name, mappings) if mappings.any?
      end
    end
  end
end
