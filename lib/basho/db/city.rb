# frozen_string_literal: true

module Basho
  module DB
    # 市区町村のActiveRecordモデル（+basho_cities+ テーブル）。
    # メモリ版 {Basho::City} と同じAPI（+full_name+, +capital?+）を提供する。
    class City < ::ActiveRecord::Base
      self.table_name = "basho_cities"
      self.primary_key = "code"

      belongs_to :prefecture,
                 class_name: "Basho::DB::Prefecture",
                 foreign_key: :prefecture_code,
                 inverse_of: :cities

      belongs_to :successor,
                 class_name: "Basho::DB::City",
                 foreign_key: :successor_code,
                 primary_key: :code,
                 optional: true

      scope :active, -> { where(deprecated_at: nil) }
      scope :deprecated, -> { where.not(deprecated_at: nil) }

      def deprecated? = deprecated_at.present?
      def active? = deprecated_at.nil?

      # 合併チェーンをたどって現行の自治体を返す（ループ検出・深度制限付き）。
      #
      # @return [Basho::DB::City]
      def current
        city = self
        seen = Set.new
        while city.successor_code.present? && seen.add?(city.successor_code)
          break if seen.size > MAX_SUCCESSOR_DEPTH

          next_city = city.successor
          break unless next_city

          city = next_city
        end
        city
      end

      # 郡名付きの正式名を返す。
      #
      # @return [String]
      def full_name
        district ? "#{district}#{name}" : name
      end
    end
  end
end
