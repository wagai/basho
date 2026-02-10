# frozen_string_literal: true

RSpec.describe Basho::PostalCode do
  describe ".find" do
    it "郵便番号で1件返す" do
      postal = described_class.find("1540011")
      expect(postal.code).to eq("1540011")
      expect(postal.prefecture_code).to eq(13)
      expect(postal.city_name).to eq("世田谷区")
      expect(postal.town).to eq("上馬")
    end

    it "ハイフン付きで検索できる" do
      postal = described_class.find("154-0011")
      expect(postal.code).to eq("1540011")
    end

    it "存在しない郵便番号はnilを返す" do
      expect(described_class.find("0000000")).to be_nil
    end

    it "不正な形式はnilを返す" do
      expect(described_class.find("123")).to be_nil
      expect(described_class.find("")).to be_nil
    end
  end

  describe ".where" do
    it "配列を返す" do
      results = described_class.where(code: "1540011")
      expect(results).to be_an(Array)
      expect(results.size).to be >= 1
      expect(results.first.code).to eq("1540011")
    end

    it "同じ郵便番号に複数の町域がある場合がある" do
      results = described_class.where(code: "1000000")
      expect(results).to be_an(Array)
    end

    it "存在しない郵便番号は空配列を返す" do
      expect(described_class.where(code: "0000000")).to eq([])
    end

    it "不正な形式は空配列を返す" do
      expect(described_class.where(code: "123")).to eq([])
      expect(described_class.where(code: "")).to eq([])
    end
  end

  describe "#formatted_code" do
    it "ハイフン付きの郵便番号を返す" do
      postal = described_class.find("1540011")
      expect(postal.formatted_code).to eq("154-0011")
    end
  end

  describe "#prefecture_name" do
    it "都道府県名を返す" do
      postal = described_class.find("1540011")
      expect(postal.prefecture_name).to eq("東京都")
    end
  end

  describe "#prefecture" do
    it "Prefectureオブジェクトを返す" do
      postal = described_class.find("1540011")
      expect(postal.prefecture).to be_a(Basho::Prefecture)
      expect(postal.prefecture.code).to eq(13)
    end
  end
end
