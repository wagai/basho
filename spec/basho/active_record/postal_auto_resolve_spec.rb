# frozen_string_literal: true

module MockActiveRecord
  ATTRS = %i[postal_code pref_name city_name town_name pref_code cty_code].freeze

  def self.included(base)
    base.include Basho
    base.attr_accessor(*ATTRS)

    base.define_method(:initialize) do |**attrs|
      ATTRS.each { |a| instance_variable_set(:"@#{a}", attrs[a]) }
      @changes = {}
    end
  end

  def will_save_change_to_attribute?(attr)
    @changes.key?(attr.to_s)
  end

  def mark_changed(attr)
    @changes[attr.to_s] = true
  end

  def run_before_save
    self.class.before_save_callbacks.each { |cb| instance_eval(&cb) }
  end
end

module MockCallbacks
  def before_save_callbacks
    @before_save_callbacks ||= []
  end

  def before_save(&block)
    before_save_callbacks << block
  end
end

RSpec.describe Basho::ActiveRecord::PostalAutoResolve do
  def build_model_class(&block)
    Class.new do
      extend MockCallbacks
      include MockActiveRecord

      class_eval(&block) if block
    end
  end

  describe "有効な郵便番号でbefore_save" do
    let(:model_class) do
      build_model_class do
        basho_postal :postal_code, prefecture: :pref_name, city: :city_name, town: :town_name
      end
    end

    it "都道府県・市区町村・町域を自動入力する" do
      record = model_class.new(postal_code: "1540011")
      record.mark_changed("postal_code")
      record.run_before_save

      expect(record.pref_name).to eq("東京都")
      expect(record.city_name).to eq("世田谷区")
      expect(record.town_name).to eq("上馬")
    end
  end

  describe "postal_codeが変更されていない場合" do
    let(:model_class) do
      build_model_class do
        basho_postal :postal_code, prefecture: :pref_name, city: :city_name, town: :town_name
      end
    end

    it "カラムを更新しない" do
      record = model_class.new(postal_code: "1540011", pref_name: "既存値")
      record.run_before_save

      expect(record.pref_name).to eq("既存値")
    end
  end

  describe "nilの郵便番号" do
    let(:model_class) do
      build_model_class do
        basho_postal :postal_code, prefecture: :pref_name, city: :city_name, town: :town_name
      end
    end

    it "カラムにnilを設定する" do
      record = model_class.new(postal_code: nil)
      record.mark_changed("postal_code")
      record.run_before_save

      expect(record.pref_name).to be_nil
      expect(record.city_name).to be_nil
      expect(record.town_name).to be_nil
    end
  end

  describe "無効な郵便番号" do
    let(:model_class) do
      build_model_class do
        basho_postal :postal_code, prefecture: :pref_name, city: :city_name, town: :town_name
      end
    end

    it "カラムにnilを設定する" do
      record = model_class.new(postal_code: "0000000")
      record.mark_changed("postal_code")
      record.run_before_save

      expect(record.pref_name).to be_nil
      expect(record.city_name).to be_nil
      expect(record.town_name).to be_nil
    end
  end

  describe "部分マッピング（prefectureのみ）" do
    let(:model_class) do
      build_model_class do
        basho_postal :postal_code, prefecture: :pref_name
      end
    end

    it "指定されたカラムだけ更新する" do
      record = model_class.new(postal_code: "1540011")
      record.mark_changed("postal_code")
      record.run_before_save

      expect(record.pref_name).to eq("東京都")
      expect(record.city_name).to be_nil
      expect(record.town_name).to be_nil
    end
  end

  describe "コードマッピング（prefecture_code, city_code）" do
    let(:model_class) do
      build_model_class do
        basho_postal :postal_code, prefecture_code: :pref_code, city_code: :cty_code
      end
    end

    it "都道府県コードと市区町村コードを保存する" do
      record = model_class.new(postal_code: "1540011")
      record.mark_changed("postal_code")
      record.run_before_save

      expect(record.pref_code).to eq(13)
      expect(record.cty_code).to be_a(String)
      expect(record.cty_code).to start_with("13")
    end

    it "nilの郵便番号ではnilを設定する" do
      record = model_class.new(postal_code: nil)
      record.mark_changed("postal_code")
      record.run_before_save

      expect(record.pref_code).to be_nil
      expect(record.cty_code).to be_nil
    end
  end

  describe "before_save非対応クラス" do
    it "Basho::Errorを発生させる" do
      expect do
        build_model_class do
          class << self
            undef_method :before_save
          end

          basho_postal :postal_code, prefecture: :pref_name
        end
      end.to raise_error(Basho::Error, /does not support before_save/)
    end
  end

  describe "後方互換（mappingsなし）" do
    let(:model_class) do
      build_model_class do
        basho_postal :postal_code
      end
    end

    it "postal_addressメソッドのみ定義される" do
      record = model_class.new(postal_code: "1540011")
      expect(record.postal_address).to eq("東京都世田谷区上馬")
    end

    it "before_saveコールバックは登録されない" do
      expect(model_class.before_save_callbacks).to be_empty
    end
  end
end
