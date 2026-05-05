# frozen_string_literal: true

module Basho
  module ActiveRecord
    # 郵便番号変更時に +before_validation+ で住所カラムを自動解決する。
    # {Base#basho_postal} のマッピングオプション指定時に使用される。
    #
    # validation の前に住所が解決されるため、validation や他の before_validation
    # callback が解決済みの住所を参照できる。
    #
    # @api private
    module PostalAutoResolve
      # サポートするマッピングキーの一覧
      MAPPING_KEYS = %i[prefecture city town prefecture_code city_code].freeze

      module_function

      # モデルに +before_validation+ コールバックを登録する。
      #
      # @param model_class [Class] ActiveRecordモデルクラス
      # @param postal_column [String] 郵便番号カラム名
      # @param mappings [Hash] マッピング設定
      # @return [void]
      def install(model_class, postal_column, mappings)
        unless model_class.respond_to?(:before_validation)
          raise Basho::Error, "#{model_class} does not support before_validation callbacks"
        end

        postal_col = postal_column.to_s
        resolved = mappings.slice(*MAPPING_KEYS).transform_values(&:to_s).freeze

        model_class.before_validation do
          next unless will_save_change_to_attribute?(postal_col)

          postal = Basho::PostalCode.find(send(postal_col))

          resolved.each do |key, target_col|
            send(:"#{target_col}=", PostalAutoResolve.resolve_value(postal, key))
          end
        end
      end

      # マッピングキーに対応する値を郵便番号データから解決する。
      #
      # @param postal [PostalCode, nil] 郵便番号データ
      # @param key [Symbol] マッピングキー
      # @return [String, Integer, nil]
      def resolve_value(postal, key)
        return nil unless postal

        case key
        when :prefecture      then postal.prefecture_name
        when :city            then postal.city_name
        when :town            then postal.town
        when :prefecture_code then postal.prefecture_code
        when :city_code       then resolve_city_code(postal)
        end
      end

      # 郵便番号データから自治体コードを逆引きする。
      #
      # @param postal [PostalCode] 郵便番号データ
      # @return [String, nil] 6桁自治体コード
      def resolve_city_code(postal)
        City.where(prefecture_code: postal.prefecture_code)
            .find { |c| c.full_name == postal.city_name }&.code
      end
    end
  end
end
