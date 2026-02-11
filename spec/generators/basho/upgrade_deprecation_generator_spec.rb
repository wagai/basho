# frozen_string_literal: true

require "rails_helper"
require "generators/basho/upgrade_deprecation/upgrade_deprecation_generator"

RSpec.describe Basho::Generators::UpgradeDeprecationGenerator do
  let(:tmp_dir) { File.expand_path("../../tmp/generators", __dir__) }

  before { FileUtils.mkdir_p(tmp_dir) }
  after  { FileUtils.rm_rf(tmp_dir) }

  def generate!
    described_class.new([], {}, destination_root: tmp_dir).create_migration_file
  end

  def migration_content
    file = Dir.glob("#{tmp_dir}/db/migrate/*add_deprecation_to_basho_cities*").first
    File.read(file)
  end

  describe "マイグレーションファイル生成" do
    before { generate! }

    it "マイグレーションファイルを生成する" do
      expect(Dir.glob("#{tmp_dir}/db/migrate/*add_deprecation_to_basho_cities*")).not_to be_empty
    end

    it "deprecated_at カラムを追加する" do
      expect(migration_content).to include("add_column :basho_cities, :deprecated_at, :datetime")
    end

    it "successor_code カラムを追加する" do
      expect(migration_content).to include("add_column :basho_cities, :successor_code, :string, limit: 6")
    end
  end
end
