# frozen_string_literal: true

require "rails_helper"
require "support/db_setup"

RSpec.describe "DB自動切り替え", :db do
  include_context "db_setup"

  describe "Basho.db?" do
    it "テーブルが存在する場合trueを返す" do
      expect(Basho.db?).to be true
    end

    it "結果をキャッシュする" do
      Basho.db?
      expect(Basho.instance_variable_get(:@db)).to be true
    end

    it "リセット後に再検出する" do
      Basho.db?
      Basho.reset_db_cache!
      expect(Basho.instance_variable_defined?(:@db)).to be false
      expect(Basho.db?).to be true
    end
  end

  describe "Basho::City" do
    describe ".find" do
      it "DB経由で返す" do
        city = Basho::City.find("131016")
        expect(city).to be_a(Basho::DB::City)
        expect(city.name).to eq("千代田区")
      end

      it "存在しないコードはnilを返す" do
        expect(Basho::City.find("999999")).to be_nil
      end

      it "不正な形式はnilを返す" do
        expect(Basho::City.find(nil)).to be_nil
        expect(Basho::City.find("123")).to be_nil
      end
    end

    describe ".where" do
      it "DB経由で返す" do
        cities = Basho::City.where(prefecture_code: 13)
        expect(cities).to be_an(Array)
        expect(cities).to all(be_a(Basho::DB::City))
        expect(cities.map(&:name)).to include("千代田区", "新宿区")
      end
    end

    it "#full_nameが使える" do
      city = Basho::City.find("473626")
      expect(city.full_name).to eq("島尻郡八重瀬町")
    end

    it "#capital?が使える" do
      expect(Basho::City.find("131041").capital?).to be true
      expect(Basho::City.find("131016").capital?).to be false
    end

    it "#prefectureがDB経由で返す" do
      city = Basho::City.find("131016")
      expect(city.prefecture).to be_a(Basho::DB::Prefecture)
      expect(city.prefecture.name).to eq("東京都")
    end
  end

  describe "Basho::Prefecture" do
    describe ".all" do
      it "DB経由で返す" do
        prefs = Basho::Prefecture.all
        expect(prefs).to be_an(Array)
        expect(prefs).to all(be_a(Basho::DB::Prefecture))
        expect(prefs.size).to eq(47)
      end
    end

    describe ".find" do
      it "codeで検索できる" do
        pref = Basho::Prefecture.find(13)
        expect(pref).to be_a(Basho::DB::Prefecture)
        expect(pref.name).to eq("東京都")
      end

      it "nameで検索できる" do
        pref = Basho::Prefecture.find(name: "大阪府")
        expect(pref).to be_a(Basho::DB::Prefecture)
        expect(pref.code).to eq(27)
      end

      it "name_enで検索できる" do
        pref = Basho::Prefecture.find(name_en: "Osaka")
        expect(pref).to be_a(Basho::DB::Prefecture)
        expect(pref.code).to eq(27)
      end

      it "存在しないコードはnilを返す" do
        expect(Basho::Prefecture.find(0)).to be_nil
        expect(Basho::Prefecture.find(48)).to be_nil
      end

      it "存在しない名前はnilを返す" do
        expect(Basho::Prefecture.find(name: "存在しない県")).to be_nil
      end
    end

    describe ".where" do
      it "regionで絞り込みできる" do
        prefs = Basho::Prefecture.where(region: "関東")
        expect(prefs).to all(be_a(Basho::DB::Prefecture))
        expect(prefs.size).to eq(7)
      end

      it "引数なしで全件返す" do
        prefs = Basho::Prefecture.where
        expect(prefs.size).to eq(47)
      end
    end

    it "#typeが使える" do
      expect(Basho::Prefecture.find(13).type).to eq("都")
      expect(Basho::Prefecture.find(1).type).to eq("道")
    end

    it "#regionが使える" do
      pref = Basho::Prefecture.find(13)
      expect(pref.region.name).to eq("関東")
    end

    it "#capitalが使える" do
      pref = Basho::Prefecture.find(13)
      capital = pref.capital
      expect(capital).to be_a(Basho::DB::City)
      expect(capital.capital?).to be true
      expect(capital.code).to eq(pref.capital_code)
    end

    it "#citiesがDB経由で返す" do
      cities = Basho::Prefecture.find(13).cities
      expect(cities.first).to be_a(Basho::DB::City)
      expect(cities.first.prefecture_code).to eq(13)
    end
  end
end
