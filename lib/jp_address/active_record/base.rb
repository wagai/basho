# frozen_string_literal: true

module JpAddress
  module ActiveRecord
    module Base
      def jp_address(column)
        column_name = column.to_s

        define_method(:city) { (c = send(column_name)) && JpAddress::City.find(c) }
        define_method(:prefecture) { city&.prefecture }
        define_method(:full_address) do
          pref = prefecture
          cty = city
          "#{pref.name}#{cty.name}" if pref && cty
        end
      end

      def jp_address_postal(column)
        column_name = column.to_s

        define_method(:postal_address) do
          code = send(column_name)
          return nil unless code

          postal = JpAddress::PostalCode.find(code).first
          return nil unless postal

          "#{postal.prefecture_name}#{postal.city_name}#{postal.town}"
        end
      end
    end
  end
end
