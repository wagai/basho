# frozen_string_literal: true

module Basho
  MAX_SUCCESSOR_DEPTH = 10
  # 市区町村を表すイミュータブルなデータクラス。
  #
  # DBバックエンドが有効な場合、クラスメソッドは自動的に {DB::City} 経由で検索する。
  #
  # @!attribute [r] code
  #   @return [String] 6桁自治体コード（JIS X 0401 + チェックディジット、例: "131016"）
  # @!attribute [r] prefecture_code
  #   @return [Integer] 都道府県コード（1〜47）
  # @!attribute [r] name
  #   @return [String] 市区町村名（例: "千代田区"）
  # @!attribute [r] name_kana
  #   @return [String] カタカナ名（例: "チヨダク"）
  # @!attribute [r] district
  #   @return [String, nil] 郡名（例: "島尻郡"）。郡に属する町村のみ設定
  # @!attribute [r] capital
  #   @return [Boolean] 県庁所在地フラグ
  # @!attribute [r] deprecated_at
  #   @return [String, nil] 廃止日（例: "2025-04-01"）。現行自治体は +nil+
  # @!attribute [r] successor_code
  #   @return [String, nil] 合併先の6桁自治体コード。合併先がない場合は +nil+
  City = ::Data.define(:code, :prefecture_code, :name, :name_kana, :district, :capital,
                       :deprecated_at, :successor_code) do
    def initialize(district: nil, capital: false, deprecated_at: nil, successor_code: nil, **)
      super
    end

    # 県庁所在地かどうかを返す。
    #
    # @return [Boolean]
    def capital? = capital

    # 郡名付きの正式名を返す。郡がない場合は {#name} と同じ。
    #
    # @return [String] 例: "島尻郡八重瀬町"
    def full_name
      district ? "#{district}#{name}" : name
    end

    # 廃止済みかどうかを返す。
    #
    # @return [Boolean]
    def deprecated? = !deprecated_at.nil?

    # 現行（未廃止）かどうかを返す。
    #
    # @return [Boolean]
    def active? = deprecated_at.nil?

    # 合併先の市区町村を返す。
    #
    # @return [City, nil]
    def successor
      City.find(successor_code) if successor_code
    end

    # 合併チェーンをたどり、現行の市区町村を返す。
    # アクティブ市区町村は即座に自身を返す。ループ検出・深度制限付き。
    #
    # @return [City]
    def current
      return self unless successor_code

      city = self
      seen = Set.new
      while city.successor_code && seen.add?(city.successor_code)
        break if seen.size > MAX_SUCCESSOR_DEPTH

        next_city = City.find(city.successor_code)
        break unless next_city

        city = next_city
      end
      city
    end

    # 所属する都道府県を返す。
    #
    # @return [Prefecture, DB::Prefecture]
    def prefecture
      Prefecture.find(prefecture_code)
    end

    class << self
      # 6桁自治体コードで市区町村を検索する。
      #
      # @param code [String] 6桁自治体コード（例: "131016"）
      # @return [City, DB::City, nil]
      def find(code)
        return nil unless code.is_a?(String) && code.size == 6
        return DB::City.find_by(code: code) if Basho.db?

        pref_code = code[0..1].to_i
        where(prefecture_code: pref_code).find { |city| city.code == code } ||
          find_deprecated(code)
      end

      # 都道府県コードで市区町村を絞り込む。
      #
      # @param prefecture_code [Integer] 都道府県コード
      # @return [Array<City>, Array<DB::City>]
      def where(prefecture_code:)
        return DB::City.where(prefecture_code: prefecture_code).to_a if Basho.db?

        Data::Loader.cities(prefecture_code).map { |data| new(**data) }
      end

      # JIS X 0401 チェックディジットで自治体コードを検証する。
      #
      # @param code [String] 6桁自治体コード
      # @return [Boolean]
      def valid_code?(code)
        CodeValidator.valid?(code)
      end

      private

      def find_deprecated(code)
        Data::Loader.deprecated_city(code)&.then { |data| new(**data) }
      end
    end
  end
end
