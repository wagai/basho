# frozen_string_literal: true

RSpec.describe Basho::Data::Loader do
  after { described_class.reset! }

  describe ".prefectures" do
    it "47都道府県のデータを返す" do
      data = described_class.prefectures
      expect(data.size).to eq(47)
    end

    it "各データが必要なキーを持つ" do
      data = described_class.prefectures.first
      expect(data).to have_key(:code)
      expect(data).to have_key(:name)
      expect(data).to have_key(:name_en)
      expect(data).to have_key(:name_kana)
      expect(data).to have_key(:name_hiragana)
      expect(data).to have_key(:region)
      expect(data).to have_key(:type)
      expect(data).to have_key(:capital_code)
    end

    it "キャッシュする" do
      first_call = described_class.prefectures
      second_call = described_class.prefectures
      expect(first_call).to equal(second_call)
    end
  end

  describe ".cities" do
    it "存在しない都道府県コードは空配列を返す" do
      expect(described_class.cities(99)).to eq([])
    end
  end

  describe ".postal_codes" do
    it "存在しない郵便番号プレフィックスは空配列を返す" do
      expect(described_class.postal_codes("000")).to eq([])
    end
  end

  describe ".reset!" do
    it "キャッシュをクリアする" do
      described_class.prefectures
      described_class.reset!
      expect(described_class.instance_variables).to be_empty
    end
  end
end
