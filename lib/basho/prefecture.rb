# frozen_string_literal: true

module Basho
  Prefecture = ::Data.define(:code, :name, :name_en, :name_kana, :name_hiragana, :region_name, :type, :capital_code) do
    def initialize(region: nil, region_name: nil, **attrs)
      super(region_name: region || region_name, **attrs)
    end

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
        @all ||= Data::Loader.prefectures.map { |data| new(**data) }
      end

      def find(code = nil, **options)
        if code
          all.find { |pref| pref.code == code }
        elsif options.any?
          find_by_options(options)
        end
      end

      def where(region: nil)
        return all unless region

        all.select { |pref| pref.region&.name == region }
      end

      private

      def find_by_options(options)
        if options[:name]
          all.find { |pref| pref.name == options[:name] }
        elsif options[:name_en]
          all.find { |pref| pref.name_en == options[:name_en] }
        end
      end
    end
  end
end
