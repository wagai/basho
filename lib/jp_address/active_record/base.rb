# frozen_string_literal: true

module JpAddress
  module ActiveRecord
    module Base
      def jp_address(column)
        column = column.to_s

        define_method(:prefecture) do
          code = send(column)
          return nil if code.nil?

          JpAddress::City.find(code)&.prefecture
        end

        define_method(:city) do
          code = send(column)
          return nil if code.nil?

          JpAddress::City.find(code)
        end

        define_method(:full_address) do
          pref = prefecture
          cty = city
          return nil if pref.nil? || cty.nil?

          "#{pref.name}#{cty.name}"
        end
      end

      def jp_address_postal(column)
        column = column.to_s

        define_method(:postal_address) do
          code = send(column)
          return nil if code.nil?

          results = JpAddress::PostalCode.find(code)
          return nil if results.empty?

          postal = results.first
          "#{postal.prefecture_name}#{postal.city_name}#{postal.town}"
        end
      end
    end
  end
end
