# frozen_string_literal: true

RSpec.describe Basho::CodeValidator do
  describe ".valid?" do
    context "正しい自治体コード" do
      %w[011002 131016 131041 271004 401005 472140].each do |code|
        it "#{code}はtrueを返す" do
          expect(described_class.valid?(code)).to be true
        end
      end
    end

    context "不正な自治体コード" do
      it "チェックディジットが不正な場合falseを返す" do
        expect(described_class.valid?("131019")).to be false
      end

      it "都道府県コードが範囲外の場合falseを返す" do
        expect(described_class.valid?("001002")).to be false
        expect(described_class.valid?("481002")).to be false
      end
    end

    context "不正な形式" do
      it "nilの場合falseを返す" do
        expect(described_class.valid?(nil)).to be false
      end

      it "5桁の場合falseを返す" do
        expect(described_class.valid?("13101")).to be false
      end

      it "7桁の場合falseを返す" do
        expect(described_class.valid?("1310161")).to be false
      end

      it "数値の場合falseを返す" do
        expect(described_class.valid?(131_016)).to be false
      end
    end
  end
end
