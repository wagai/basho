# frozen_string_literal: true

RSpec.describe Basho::Prefecture do
  describe ".all" do
    it "47都道府県を返す" do
      expect(described_class.all.size).to eq(47)
    end
  end

  describe ".find" do
    context "コードで検索" do
      it "東京都を返す" do
        pref = described_class.find(13)
        expect(pref.name).to eq("東京都")
        expect(pref.code).to eq(13)
        expect(pref.name_en).to eq("Tokyo")
        expect(pref.name_kana).to eq("トウキョウト")
        expect(pref.name_hiragana).to eq("とうきょうと")
        expect(pref.type).to eq("都")
        expect(pref.capital_code).to eq("131041")
      end

      it "北海道を返す" do
        pref = described_class.find(1)
        expect(pref.name).to eq("北海道")
        expect(pref.type).to eq("道")
      end

      it "京都府を返す" do
        pref = described_class.find(26)
        expect(pref.name).to eq("京都府")
        expect(pref.type).to eq("府")
      end

      it "存在しないコードはnilを返す" do
        expect(described_class.find(0)).to be_nil
        expect(described_class.find(48)).to be_nil
      end
    end

    context "名前で検索" do
      it "日本語名で検索できる" do
        pref = described_class.find(name: "大阪府")
        expect(pref.code).to eq(27)
      end

      it "英語名で検索できる" do
        pref = described_class.find(name_en: "Osaka")
        expect(pref.code).to eq(27)
      end

      it "存在しない名前はnilを返す" do
        expect(described_class.find(name: "存在しない県")).to be_nil
      end
    end
  end

  describe ".where" do
    it "地方で絞り込みできる" do
      prefs = described_class.where(region: "関東")
      expect(prefs.size).to eq(7)
      expect(prefs.map(&:name)).to include("東京都", "神奈川県", "埼玉県")
    end

    it "引数なしで全件返す" do
      expect(described_class.where.size).to eq(47)
    end
  end

  describe "#region" do
    it "所属する地方を返す" do
      pref = described_class.find(13)
      expect(pref.region.name).to eq("関東")
    end
  end

  describe "#cities" do
    it "所属する市区町村を返す" do
      cities = described_class.find(13).cities
      expect(cities).to be_an(Array)
      expect(cities).to all(be_a(Basho::City))
      expect(cities.first.prefecture_code).to eq(13)
    end
  end

  describe "#capital" do
    it "県庁所在地を返す" do
      pref = described_class.find(13)
      capital = pref.capital
      expect(capital).to be_a(Basho::City)
      expect(capital.capital?).to be true
      expect(capital.code).to eq(pref.capital_code)
    end
  end

  describe "4種の都道府県タイプ" do
    it "都・道・府・県がある" do
      types = described_class.all.map(&:type).uniq
      expect(types).to contain_exactly("都", "道", "府", "県")
    end

    it "都は1つ" do
      expect(described_class.all.count { |p| p.type == "都" }).to eq(1)
    end

    it "道は1つ" do
      expect(described_class.all.count { |p| p.type == "道" }).to eq(1)
    end

    it "府は2つ" do
      expect(described_class.all.count { |p| p.type == "府" }).to eq(2)
    end

    it "県は43" do
      expect(described_class.all.count { |p| p.type == "県" }).to eq(43)
    end
  end
end
