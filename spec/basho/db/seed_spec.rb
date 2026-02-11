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
    it "2回実行してもアクティブ件数が変わらない" do
      described_class.seed!
      first_count = Basho::DB::City.active.count

      described_class.seed!

      expect(Basho::DB::Prefecture.count).to eq(47)
      expect(Basho::DB::City.active.count).to eq(first_count)
    end

    it "2回実行してもcodeの集合が同一" do
      described_class.seed!
      codes_before = Basho::DB::City.order(:code).pluck(:code)

      described_class.seed!

      expect(Basho::DB::City.order(:code).pluck(:code)).to eq(codes_before)
    end
  end

  describe "upsert更新" do
    it "名前変更がDBに反映される（update_only に含まれるカラム）" do
      city = Basho::DB::City.find("011002")
      original_name = city.name

      city.update_columns(name: "テスト市")
      expect(city.reload.name).to eq("テスト市")

      described_class.seed!

      expect(city.reload.name).to eq(original_name)
    end
  end

  describe "論理削除" do
    after do
      Basho::DB::City.where.not(deprecated_at: nil).update_all(deprecated_at: nil)
    end

    it "gemデータにない市区町村に deprecated_at が設定される" do
      target = Basho::DB::City.active.first
      fake_cities = described_class.send(:city_rows).reject { |c| c[:code] == target.code }

      allow(described_class).to receive(:city_rows).and_return(fake_cities)
      described_class.seed!

      expect(target.reload.deprecated_at).to be_present
    end

    it "gemデータに残っている市区町村は deprecated_at が設定されない" do
      described_class.seed!
      expect(Basho::DB::City.deprecated.count).to eq(0)
    end
  end

  describe "手動設定の保持（update_only 対象外カラム）" do
    after do
      Basho::DB::City
        .where(code: "011002")
        .update_all(deprecated_at: nil, successor_code: nil)
    end

    it "successor_code が seed で上書きされない" do
      city = Basho::DB::City.find("011002")
      city.update_columns(successor_code: "131016")

      described_class.seed!

      expect(city.reload.successor_code).to eq("131016")
    end

    it "deprecated_at が seed で上書きされない" do
      city = Basho::DB::City.find("011002")
      frozen_time = Time.utc(2025, 1, 1)
      city.update_columns(deprecated_at: frozen_time)

      described_class.seed!

      expect(city.reload.deprecated_at).to eq(frozen_time)
    end
  end

  describe ".seed_fresh?" do
    after do
      Basho::DB::City.update_all(deprecated_at: nil)
    end

    it "seed 直後は true" do
      expect(described_class).to be_seed_fresh
    end

    it "廃止レコードがあると false（アクティブ件数がgemデータと不一致）" do
      Basho::DB::City.limit(1).update_all(deprecated_at: Time.current)
      expect(described_class).not_to be_seed_fresh
    end
  end

  describe "データ整合性" do
    it "全市区町村が既存の都道府県に属する" do
      orphan_codes = Basho::DB::City.distinct.pluck(:prefecture_code) -
                     Basho::DB::Prefecture.pluck(:code)
      expect(orphan_codes).to be_empty
    end

    it "47都道府県すべてに市区町村がある" do
      codes_with_cities = Basho::DB::City.distinct.pluck(:prefecture_code)
      expect(codes_with_cities.sort).to eq((1..47).to_a)
    end
  end
end
