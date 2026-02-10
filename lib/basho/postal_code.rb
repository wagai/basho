# frozen_string_literal: true

module Basho
  PostalCode = ::Data.define(:code, :prefecture_code, :city_name, :town) do
    def initialize(city: nil, city_name: nil, **attrs)
      super(city_name: city || city_name, **attrs)
    end

    def formatted_code
      "#{code[0..2]}-#{code[3..]}"
    end

    def prefecture_name
      prefecture&.name
    end

    def prefecture
      Prefecture.find(prefecture_code)
    end

    class << self
      def find(code)
        where(code).first
      end

      def where(code)
        normalized = code.to_s.delete("-")
        return [] unless normalized.match?(/\A\d{7}\z/)

        prefix = normalized[0..2]
        Data::Loader.postal_codes(prefix)
                    .filter_map { |data| new(**data) if data[:code] == normalized }
      end
    end
  end
end
