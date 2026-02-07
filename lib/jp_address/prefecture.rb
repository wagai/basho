# frozen_string_literal: true

module JpAddress
  class Prefecture
    attr_reader :code, :name, :name_e, :name_k, :name_h, :type, :capital_code

    def initialize(code:, name:, name_e:, name_k:, name_h:, region:, type:, capital_code:)
      @code = code
      @name = name
      @name_e = name_e
      @name_k = name_k
      @name_h = name_h
      @region_name = region
      @type = type
      @capital_code = capital_code
    end

    def region
      Region.find(@region_name)
    end

    def cities
      City.where(prefecture_code: @code)
    end

    def capital
      City.find(@capital_code)
    end

    class << self
      def all
        @all ||= Data::Loader.prefectures.map { |data| new(**data) }
      end

      def find(code_or_options = nil, **options)
        if code_or_options.is_a?(Integer)
          all.find { |pref| pref.code == code_or_options }
        elsif code_or_options.is_a?(Hash)
          find_by_options(code_or_options)
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
        elsif options[:name_e]
          all.find { |pref| pref.name_e == options[:name_e] }
        end
      end
    end
  end
end
