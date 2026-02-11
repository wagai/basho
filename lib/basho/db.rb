# frozen_string_literal: true

require "active_record"
require_relative "db/prefecture"
require_relative "db/city"

module Basho
  module DB
    # JSON → DB の一括投入（冪等）
    def self.seed!
      prefs = prefecture_rows
      cities = city_rows

      ::ActiveRecord::Base.transaction do
        City.delete_all
        Prefecture.delete_all

        Prefecture.insert_all!(prefs)
        City.insert_all!(cities)
      end

      { prefectures: prefs.size, cities: cities.size }
    end

    def self.prefecture_rows
      Data::Loader.prefectures.map do |pref|
        pref.except(:type).merge(prefecture_type: pref[:type])
      end
    end
    private_class_method :prefecture_rows

    def self.city_rows
      (1..47).flat_map do |code|
        Data::Loader.cities(code).map do |city|
          { district: nil, capital: false, **city }
        end
      end
    end
    private_class_method :city_rows
  end
end
