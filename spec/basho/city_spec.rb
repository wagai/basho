# frozen_string_literal: true

RSpec.describe Basho::City do
  describe ".find" do
    it "自治体コードで検索できる" do
      city = described_class.find("131016")
      expect(city.code).to eq("131016")
      expect(city.name).to eq("千代田区")
      expect(city.name_kana).to eq("チヨダク")
      expect(city.prefecture_code).to eq(13)
    end

    it "県庁所在地フラグを持つ" do
      city = described_class.find("131041")
      expect(city.name).to eq("新宿区")
      expect(city.capital?).to be true
    end

    it "県庁所在地でない場合はfalse" do
      city = described_class.find("131016")
      expect(city.capital?).to be false
    end

    it "存在しないコードはnilを返す" do
      expect(described_class.find("999999")).to be_nil
    end

    it "不正な形式はnilを返す" do
      expect(described_class.find(nil)).to be_nil
      expect(described_class.find("123")).to be_nil
    end
  end

  describe ".where" do
    after { described_class.reset! }

    it "結果をキャッシュする" do
      first_call = described_class.where(prefecture_code: 13)
      second_call = described_class.where(prefecture_code: 13)
      expect(first_call).to equal(second_call)
    end

    it "都道府県コードで絞り込みできる" do
      cities = described_class.where(prefecture_code: 13)
      expect(cities).to be_an(Array)
      expect(cities.size).to be > 0
      expect(cities.map(&:name)).to include("千代田区", "新宿区", "渋谷区")
    end

    it "各市区町村がprefecture_codeを持つ" do
      cities = described_class.where(prefecture_code: 1)
      cities.each do |city|
        expect(city.prefecture_code).to eq(1)
      end
    end
  end

  describe ".valid_code?" do
    it "正しい自治体コードはtrueを返す" do
      expect(described_class.valid_code?("131016")).to be true
      expect(described_class.valid_code?("011002")).to be true
    end

    it "不正な自治体コードはfalseを返す" do
      expect(described_class.valid_code?("131019")).to be false
      expect(described_class.valid_code?("000000")).to be false
    end

    it "不正な形式はfalseを返す" do
      expect(described_class.valid_code?("12345")).to be false
      expect(described_class.valid_code?("1234567")).to be false
      expect(described_class.valid_code?(nil)).to be false
    end
  end

  describe "#prefecture" do
    it "所属する都道府県を返す" do
      city = described_class.find("131016")
      expect(city.prefecture.name).to eq("東京都")
    end
  end
end
