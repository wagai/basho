# frozen_string_literal: true

module Basho
  City = ::Data.define(:code, :prefecture_code, :name, :name_kana, :capital) do
    def initialize(capital: false, **)
      super
    end

    def capital? = capital

    def prefecture
      Prefecture.find(prefecture_code)
    end

    class << self
      def find(code)
        return nil unless code.is_a?(String) && code.size == 6

        prefecture_code = code[0..1].to_i
        where(prefecture_code: prefecture_code).find { |city| city.code == code }
      end

      def where(prefecture_code:)
        cities_cache[prefecture_code] ||=
          Data::Loader.cities(prefecture_code).map { |data| new(**data) }.freeze
      end

      def valid_code?(code)
        CodeValidator.valid?(code)
      end

      def reset!
        @cities_cache = nil
      end

      private

      def cities_cache
        @cities_cache ||= {}
      end
    end
  end
end
