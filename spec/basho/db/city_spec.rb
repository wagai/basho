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

  # ── 廃止・合併 ──────────────────────────────────

  describe "廃止・合併" do
    let(:city_a) { described_class.find("011002") }  # 札幌市
    let(:city_b) { described_class.find("131016") }  # 千代田区
    let(:city_c) { described_class.find("271004") }  # 大阪市

    after do
      described_class
        .where(code: %w[011002 131016 271004])
        .update_all(deprecated_at: nil, successor_code: nil)
    end

    describe ".active / .deprecated" do
      before { city_a.update_columns(deprecated_at: Time.current) }

      it ".active は廃止でないレコードのみ返す" do
        expect(described_class.active.pluck(:code)).not_to include(city_a.code)
        expect(described_class.active).to all(have_attributes(deprecated_at: nil))
      end

      it ".deprecated は廃止レコードのみ返す" do
        expect(described_class.deprecated.pluck(:code)).to eq([city_a.code])
      end

      it "active + deprecated = 全レコード（補完性）" do
        total = described_class.count
        expect(described_class.active.count + described_class.deprecated.count).to eq(total)
      end
    end

    describe "#deprecated? / #active?" do
      it "deprecated_at なし → active かつ not deprecated" do
        expect(city_a).to be_active
        expect(city_a).not_to be_deprecated
      end

      it "deprecated_at あり → deprecated かつ not active" do
        city_a.update_columns(deprecated_at: Time.current)
        expect(city_a).to be_deprecated
        expect(city_a).not_to be_active
      end
    end

    describe "#successor" do
      it "successor_code がある場合、合併先を返す" do
        city_a.update_columns(successor_code: city_b.code)
        expect(city_a.successor).to eq(city_b)
      end

      it "successor_code が nil なら nil" do
        expect(city_a.successor).to be_nil
      end

      it "存在しない successor_code なら nil" do
        city_a.update_columns(successor_code: "999999")
        expect(city_a.successor).to be_nil
      end
    end

    describe "#current" do
      it "successor なし → 自身を返す" do
        expect(city_a.current).to eq(city_a)
      end

      it "チェーン A→B→C → 終端 C を返す" do
        city_a.update_columns(successor_code: city_b.code)
        city_b.update_columns(successor_code: city_c.code)
        expect(city_a.current).to eq(city_c)
      end

      it "中間から辿っても終端に到達する（B→C）" do
        city_a.update_columns(successor_code: city_b.code)
        city_b.update_columns(successor_code: city_c.code)
        expect(city_b.current).to eq(city_c)
      end

      it "ループ A→B→A → 無限ループせず停止する" do
        city_a.update_columns(successor_code: city_b.code)
        city_b.update_columns(successor_code: city_a.code)

        expect { city_a.current }.not_to raise_error
        expect([city_a, city_b]).to include(city_a.current)
      end

      it "存在しない successor_code → 自身を返す" do
        city_a.update_columns(successor_code: "999999")
        expect(city_a.current).to eq(city_a)
      end
    end
  end
end
