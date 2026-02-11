# frozen_string_literal: true

require "active_record"
require_relative "db/prefecture"
require_relative "db/city"

module Basho
  # ActiveRecordバックエンド（オプション）。
  # +basho_prefectures+ / +basho_cities+ テーブルへのアクセスとシードを提供する。
  module DB
    # JSONデータをDBに一括投入する。冪等（何度実行しても同じ結果）。
    # upsert_allで既存レコードを保持しつつ更新し、gemデータから消えた市区町村は論理削除する。
    #
    # @return [Hash{Symbol => Integer}] 投入件数（+:prefectures+, +:cities+）
    def self.seed!
      prefs = prefecture_rows
      cities = city_rows

      ::ActiveRecord::Base.transaction do
        Prefecture.upsert_all(prefs, unique_by: :code)
        upsert_cities(cities)
        deprecate_removed_cities(cities)
      end

      { prefectures: prefs.size, cities: cities.size }
    end

    # DBのアクティブな市区町村件数がgemの同梱データと一致するか判定する。
    # 市区町村の合併・分割で件数が変わるため、不一致はシード更新が必要なサイン。
    #
    # @return [Boolean]
    def self.seed_fresh?
      expected = (1..47).sum { |code| Data::Loader.cities(code).size }
      City.active.count == expected
    rescue ::ActiveRecord::ActiveRecordError
      false
    end

    def self.upsert_cities(cities)
      City.upsert_all(
        cities,
        unique_by: :code,
        update_only: %i[prefecture_code name name_kana district capital]
      )
    end
    private_class_method :upsert_cities

    def self.deprecate_removed_cities(cities)
      gem_codes = cities.to_set { |c| c[:code] }
      stale_codes = City.where(deprecated_at: nil).pluck(:code).reject { |c| gem_codes.include?(c) }
      City.where(code: stale_codes).update_all(deprecated_at: Time.current) if stale_codes.any?
    end
    private_class_method :deprecate_removed_cities

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
