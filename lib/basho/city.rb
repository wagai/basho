# frozen_string_literal: true

module Basho
  City = ::Data.define(:code, :prefecture_code, :name, :name_kana, :district, :capital) do
    def initialize(district: nil, capital: false, **)
      super
    end

    def capital? = capital

    def full_name
      district ? "#{district}#{name}" : name
    end

    def prefecture
      Prefecture.find(prefecture_code)
    end

    class << self
      def find(code)
        return nil unless code.is_a?(String) && code.size == 6
        return DB::City.find_by(code: code) if Basho.db?

        pref_code = code[0..1].to_i
        where(prefecture_code: pref_code).find { |city| city.code == code }
      end

      def where(prefecture_code:)
        return DB::City.where(prefecture_code: prefecture_code).to_a if Basho.db?

        Data::Loader.cities(prefecture_code).map { |data| new(**data) }
      end

      def valid_code?(code)
        CodeValidator.valid?(code)
      end
    end
  end
end
