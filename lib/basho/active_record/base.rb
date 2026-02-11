# frozen_string_literal: true

require_relative "postal_auto_resolve"

module Basho
  # ActiveRecord統合機能を提供する名前空間。
  module ActiveRecord
    # ActiveRecordモデルに +basho+ / +basho_postal+ マクロを提供するモジュール。
    # +include Basho+ で自動的に extend される。
    #
    # @example
    #   class Shop < ApplicationRecord
    #     include Basho
    #     basho :city_code
    #     basho_postal :postal_code, prefecture: :pref_name, city: :city_name
    #   end
    module Base
      # 自治体コードカラムから +city+, +prefecture+, +full_address+ メソッドと
      # +with_basho+ スコープを定義する。
      #
      # DBモードでは +belongs_to :basho_city+ と +has_one :basho_prefecture+ を追加し、
      # +with_basho+ スコープでN+1クエリを防止する。
      # メモリモードでは +with_basho+ はno-op（+all+）となる。
      #
      # @param column [Symbol, String] 6桁自治体コードを格納するカラム名
      # @return [void]
      def basho(column)
        column_name = column.to_s
        Basho.db? ? basho_db_mode(column_name) : basho_memory_mode(column_name)
        basho_define_full_address
      end

      # 郵便番号カラムから +postal_address+ メソッドを定義する。
      # マッピングオプションを渡すと +before_save+ で住所カラムを自動入力する。
      #
      # @param column [Symbol, String] 郵便番号を格納するカラム名
      # @param mappings [Hash] マッピングオプション
      # @option mappings [Symbol] :prefecture 都道府県名の保存先カラム
      # @option mappings [Symbol] :city 市区町村名の保存先カラム
      # @option mappings [Symbol] :town 町域名の保存先カラム
      # @option mappings [Symbol] :prefecture_code 都道府県コードの保存先カラム
      # @option mappings [Symbol] :city_code 自治体コードの保存先カラム
      # @return [void]
      def basho_postal(column, **mappings)
        column_name = column.to_s

        define_method(:postal_address) do
          code = send(column_name)
          return nil unless code

          postal = Basho::PostalCode.find(code)
          return nil unless postal

          "#{postal.prefecture_name}#{postal.city_name}#{postal.town}"
        end

        PostalAutoResolve.install(self, column_name, mappings) if mappings.any?
      end

      private

      # @private DBモードのアソシエーションとスコープを定義する。
      def basho_db_mode(column_name)
        basho_db_associations(column_name)
        scope :with_basho, -> { includes(basho_city: :prefecture) }
        basho_db_methods
      end

      # @private DBモードのアソシエーションを定義する。
      def basho_db_associations(column_name)
        belongs_to :basho_city,
                   class_name: "Basho::DB::City",
                   foreign_key: column_name,
                   primary_key: "code",
                   optional: true

        has_one :basho_prefecture,
                through: :basho_city,
                source: :prefecture
      end

      # @private DBモードのインスタンスメソッドを定義する。
      def basho_db_methods
        define_method(:city) { basho_city }
        define_method(:prefecture) do
          if association(:basho_prefecture).loaded?
            basho_prefecture
          else
            basho_city&.prefecture
          end
        end
      end

      # @private メモリモードのスコープ・メソッドを定義する。
      def basho_memory_mode(column_name)
        scope(:with_basho, -> { all }) if respond_to?(:scope)

        define_method(:city) { (c = send(column_name)) && Basho::City.find(c) }
        define_method(:prefecture) { city&.prefecture }
      end

      # @private full_addressメソッドを定義する。
      def basho_define_full_address
        define_method(:full_address) do
          pref = prefecture
          cty = city
          "#{pref.name}#{cty.name}" if pref && cty
        end
      end
    end
  end
end
