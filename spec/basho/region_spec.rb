# frozen_string_literal: true

RSpec.describe Basho::Region do
  describe ".all" do
    it "9地方を返す" do
      expect(described_class.all.size).to eq(9)
    end

    it "各地方がname, name_en, prefecture_codesを持つ" do
      region = described_class.all.first
      expect(region.name).to eq("北海道")
      expect(region.name_en).to eq("Hokkaido")
      expect(region.prefecture_codes).to eq([1])
    end
  end

  describe ".find" do
    it "日本語名で検索できる" do
      region = described_class.find("関東")
      expect(region.name).to eq("関東")
      expect(region.prefecture_codes).to eq([8, 9, 10, 11, 12, 13, 14])
    end

    it "英語名で検索できる" do
      region = described_class.find("Kanto")
      expect(region.name).to eq("関東")
    end

    it "存在しない地方はnilを返す" do
      expect(described_class.find("存在しない")).to be_nil
    end
  end

  describe "#prefectures" do
    it "所属する都道府県を返す" do
      region = described_class.find("四国")
      prefectures = region.prefectures
      expect(prefectures.size).to eq(4)
      expect(prefectures.map(&:name)).to contain_exactly("徳島県", "香川県", "愛媛県", "高知県")
    end
  end

  describe "全都道府県がいずれかの地方に属する" do
    it "47都道府県すべてのコードが含まれる" do
      all_codes = described_class.all.flat_map(&:prefecture_codes).sort
      expect(all_codes).to eq((1..47).to_a)
    end
  end
end
