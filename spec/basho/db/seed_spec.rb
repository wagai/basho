# frozen_string_literal: true

require "rails_helper"
require "support/db_setup"

RSpec.describe Basho::DB, ".seed!" do
  include_context "db_setup"

  describe "戻り値" do
    it "投入件数を返す" do
      counts = described_class.seed!
      expect(counts[:prefectures]).to eq(47)
      expect(counts[:cities]).to be > 1700
    end
  end

  describe "冪等性" do
    it "2回実行しても件数が変わらない" do
      described_class.seed!
      described_class.seed!

      expect(Basho::DB::Prefecture.count).to eq(47)
      expect(Basho::DB::City.count).to be > 1700
    end
  end

  describe "データ整合性" do
    it "全市区町村が既存の都道府県に属する" do
      pref_codes = Basho::DB::Prefecture.pluck(:code)
      city_pref_codes = Basho::DB::City.distinct.pluck(:prefecture_code)

      expect(city_pref_codes - pref_codes).to be_empty
    end

    it "47都道府県すべてに市区町村がある" do
      codes_with_cities = Basho::DB::City.distinct.pluck(:prefecture_code)
      expect(codes_with_cities.sort).to eq((1..47).to_a)
    end
  end
end
