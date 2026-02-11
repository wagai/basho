# frozen_string_literal: true

require "basho/db"

RSpec.shared_context "db_setup" do
  before(:all) do
    ActiveRecord::Base.connection.disable_referential_integrity do
      ActiveRecord::Schema.define do
        create_table :basho_prefectures, id: false, force: true do |t|
          t.integer :code, null: false, primary_key: true
          t.string :name, null: false
          t.string :name_en, null: false
          t.string :name_kana, null: false
          t.string :name_hiragana, null: false
          t.string :region_name, null: false
          t.string :prefecture_type, null: false
          t.string :capital_code, limit: 6
        end

        create_table :basho_cities, id: false, force: true do |t|
          t.string :code, limit: 6, null: false, primary_key: true
          t.integer :prefecture_code, null: false
          t.string :name, null: false
          t.string :name_kana, null: false
          t.string :district
          t.boolean :capital, null: false, default: false
        end
      end
    end

    Basho::DB.seed!
  end
end
