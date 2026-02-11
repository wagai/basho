# frozen_string_literal: true

require "rails_helper"
require "support/db_setup"

RSpec.describe Basho::DB::City do
  include_context "db_setup"

  describe "レコード数" do
    it "市区町村が存在する" do
      expect(described_class.count).to be > 1700
    end
  end

  describe ".find" do
    it "自治体コードで検索できる" do
      city = described_class.find("131016")
      expect(city.code).to eq("131016")
      expect(city.name).to eq("千代田区")
      expect(city.name_kana).to eq("チヨダク")
      expect(city.prefecture_code).to eq(13)
    end
  end

  describe ".find_by" do
    it "存在しないコードはnilを返す" do
      expect(described_class.find_by(code: "999999")).to be_nil
    end
  end

  describe ".where" do
    it "都道府県コードで絞り込みできる" do
      cities = described_class.where(prefecture_code: 13)
      expect(cities.size).to be > 0
      expect(cities.map(&:name)).to include("千代田区", "新宿区", "渋谷区")
    end

    it "各市区町村がprefecture_codeを持つ" do
      described_class.where(prefecture_code: 1).each do |city|
        expect(city.prefecture_code).to eq(1)
      end
    end
  end

  describe "#prefecture" do
    it "所属する都道府県を返す" do
      chiyoda = described_class.find("131016")
      expect(chiyoda.prefecture).to be_a(Basho::DB::Prefecture)
      expect(chiyoda.prefecture.name).to eq("東京都")
    end
  end

  describe "#capital?" do
    it "県庁所在地はtrueを返す" do
      sapporo = described_class.find("011002")
      expect(sapporo.capital?).to be true
    end

    it "県庁所在地以外はfalseを返す" do
      chiyoda = described_class.find("131016")
      expect(chiyoda.capital?).to be false
    end
  end

  describe "#district" do
    it "郡に属する町村は郡名を持つ" do
      city = described_class.find("473626")
      expect(city.name).to eq("八重瀬町")
      expect(city.district).to eq("島尻郡")
    end

    it "市・区は郡名を持たない" do
      city = described_class.find("131016")
      expect(city.district).to be_nil
    end
  end

  describe "#full_name" do
    it "郡名付きの正式名を返す" do
      city = described_class.find("473626")
      expect(city.full_name).to eq("島尻郡八重瀬町")
    end

    it "郡がない場合はnameと同じ" do
      city = described_class.find("131016")
      expect(city.full_name).to eq("千代田区")
    end
  end
end
