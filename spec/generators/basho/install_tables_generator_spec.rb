# frozen_string_literal: true

require "rails_helper"
require "generators/basho/install_tables/install_tables_generator"

RSpec.describe Basho::Generators::InstallTablesGenerator do
  let(:tmp_dir) { File.expand_path("../../tmp/generators", __dir__) }

  before { FileUtils.mkdir_p(tmp_dir) }
  after  { FileUtils.rm_rf(tmp_dir) }

  def generate!
    described_class.new([], {}, destination_root: tmp_dir).create_migration_files
  end

  def migration_content(table_name)
    file = Dir.glob("#{tmp_dir}/db/migrate/*#{table_name}*").first
    File.read(file)
  end

  describe "マイグレーションファイル生成" do
    before { generate! }

    it "basho_prefectures と basho_cities のマイグレーションを生成する" do
      expect(Dir.glob("#{tmp_dir}/db/migrate/*create_basho_prefectures*")).not_to be_empty
      expect(Dir.glob("#{tmp_dir}/db/migrate/*create_basho_cities*")).not_to be_empty
    end

    it "prefectures テーブルに code を主キーとして定義する" do
      content = migration_content("create_basho_prefectures")
      expect(content).to include("t.integer :code, null: false, primary_key: true")
    end

    it "cities テーブルに prefecture_code の外部キーを定義する" do
      content = migration_content("create_basho_cities")
      expect(content).to include("t.integer :prefecture_code, null: false")
      expect(content).to include("add_foreign_key :basho_cities, :basho_prefectures, column: :prefecture_code, primary_key: :code")
    end
  end
end
