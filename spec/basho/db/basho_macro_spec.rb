# frozen_string_literal: true

require "rails_helper"
require "support/db_setup"
require "support/query_counter"

RSpec.describe "bashoマクロ（DBモード）", :db do
  include_context "db_setup"
  include QueryCounter

  before(:all) do
    ActiveRecord::Schema.define do
      create_table :dummy_shops, force: true do |t|
        t.string :city_code, limit: 6
      end
    end

    Basho.db = true

    Object.send(:remove_const, :DummyShop) if defined?(DummyShop)
    Object.const_set(:DummyShop, Class.new(ActiveRecord::Base) do
      self.table_name = "dummy_shops"
      include Basho

      basho :city_code
    end)
  end

  after(:all) do
    ActiveRecord::Schema.define do
      drop_table :dummy_shops, if_exists: true
    end
  end

  describe "アソシエーション定義" do
    it "belongs_to :basho_city が定義される" do
      reflection = DummyShop.reflect_on_association(:basho_city)
      expect(reflection).to be_present
      expect(reflection.macro).to eq(:belongs_to)
      expect(reflection.class_name).to eq("Basho::DB::City")
      expect(reflection.foreign_key).to eq("city_code")
    end

    it "has_one :basho_prefecture が定義される" do
      reflection = DummyShop.reflect_on_association(:basho_prefecture)
      expect(reflection).to be_present
      expect(reflection.macro).to eq(:has_one)
      expect(reflection.source_reflection.name).to eq(:prefecture)
    end

    it "scope :with_basho が定義される" do
      expect(DummyShop).to respond_to(:with_basho)
    end
  end

  describe "#city" do
    it "basho_city経由で市区町村を返す" do
      shop = DummyShop.create!(city_code: "131016")
      expect(shop.city).to be_a(Basho::DB::City)
      expect(shop.city.name).to eq("千代田区")
    end

    it "city_codeがnilならnilを返す" do
      shop = DummyShop.new(city_code: nil)
      expect(shop.city).to be_nil
    end
  end

  describe "#prefecture" do
    it "basho_city経由で都道府県を返す" do
      shop = DummyShop.create!(city_code: "131016")
      expect(shop.prefecture).to be_a(Basho::DB::Prefecture)
      expect(shop.prefecture.name).to eq("東京都")
    end

    it "city_codeがnilならnilを返す" do
      shop = DummyShop.new(city_code: nil)
      expect(shop.prefecture).to be_nil
    end
  end

  describe "#full_address" do
    it "都道府県名+市区町村名を返す" do
      shop = DummyShop.create!(city_code: "131016")
      expect(shop.full_address).to eq("東京都千代田区")
    end

    it "city_codeがnilならnilを返す" do
      shop = DummyShop.new(city_code: nil)
      expect(shop.full_address).to be_nil
    end
  end

  describe "N+1パフォーマンス検証" do
    before do
      DummyShop.delete_all
      DummyShop.create!(city_code: "131016") # 千代田区
      DummyShop.create!(city_code: "131041") # 新宿区
      DummyShop.create!(city_code: "271276") # 堺市堺区
    end

    it "includesなしではcityアクセスで追加クエリが発生する" do
      shops = DummyShop.all.to_a
      queries = count_queries { shops.each(&:city) }
      expect(queries).to be >= shops.size
    end

    it "includes(:basho_city)でcityアクセスの追加クエリが0になる" do
      shops = DummyShop.includes(:basho_city).to_a
      queries = count_queries { shops.each(&:city) }
      expect(queries).to eq(0)
    end

    it "includes(basho_city: :prefecture)でprefectureアクセスの追加クエリが0になる" do
      shops = DummyShop.includes(basho_city: :prefecture).to_a
      queries = count_queries { shops.each(&:prefecture) }
      expect(queries).to eq(0)
    end

    it "with_bashoでcity+prefectureアクセスの追加クエリが0になる" do
      shops = DummyShop.with_basho.to_a
      queries = count_queries do
        shops.each do |shop|
          shop.city
          shop.prefecture
        end
      end
      expect(queries).to eq(0)
    end

    it "includes(:basho_prefecture)でprefecture直接プリロードの追加クエリが0になる" do
      shops = DummyShop.includes(:basho_prefecture).to_a
      queries = count_queries { shops.each(&:prefecture) }
      expect(queries).to eq(0)
    end
  end
end
