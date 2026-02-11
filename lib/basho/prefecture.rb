# frozen_string_literal: true

module Basho
  Prefecture = ::Data.define(:code, :name, :name_en, :name_kana, :name_hiragana, :region_name, :type, :capital_code) do
    def region
      Region.find(region_name)
    end

    def cities
      City.where(prefecture_code: code)
    end

    def capital
      City.find(capital_code)
    end

    class << self
      def all
        return DB::Prefecture.all.to_a if Basho.db?

        @all ||= Data::Loader.prefectures.map { |data| new(**data) }.freeze
      end

      def find(code = nil, **options)
        attrs = code.nil? ? options : { code: code }
        return if attrs.empty?

        key, value = attrs.first
        return DB::Prefecture.find_by(key => value) if Basho.db?

        all.find { |pref| pref.public_send(key) == value }
      end

      def where(region: nil)
        return all unless region
        return DB::Prefecture.where(region_name: region).to_a if Basho.db?

        all.select { |pref| pref.region_name == region }
      end

      def reset_cache!
        remove_instance_variable(:@all) if defined?(@all)
      end
    end
  end
end
