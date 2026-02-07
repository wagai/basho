# frozen_string_literal: true

module JpAddress
  class PostalCode
    attr_reader :code, :prefecture_code, :city_name, :town

    def initialize(code:, prefecture_code:, city:, town:)
      @code = code
      @prefecture_code = prefecture_code
      @city_name = city
      @town = town
    end

    def formatted_code
      "#{@code[0..2]}-#{@code[3..]}"
    end

    def prefecture_name
      prefecture&.name
    end

    def prefecture
      Prefecture.find(@prefecture_code)
    end

    class << self
      def find(code)
        normalized = code.to_s.delete("-")
        return [] unless normalized.match?(/\A\d{7}\z/)

        prefix = normalized[0..2]
        Data::Loader.postal_codes(prefix)
                    .select { |data| data[:code] == normalized }
                    .map { |data| new(**data) }
      end
    end
  end
end
