# frozen_string_literal: true

module Basho
  module ActiveRecord
    # 郵便番号変更時にbefore_saveで住所カラムを自動解決する
    module PostalAutoResolve
      MAPPING_KEYS = %i[prefecture city town prefecture_code city_code].freeze

      module_function

      def install(model_class, postal_column, mappings)
        unless model_class.respond_to?(:before_save)
          raise Basho::Error, "#{model_class} does not support before_save callbacks"
        end

        postal_col = postal_column.to_s
        resolved = mappings.slice(*MAPPING_KEYS).transform_values(&:to_s).freeze

        model_class.before_save do
          next unless will_save_change_to_attribute?(postal_col)

          postal = Basho::PostalCode.find(send(postal_col))

          resolved.each do |key, target_col|
            send(:"#{target_col}=", PostalAutoResolve.resolve_value(postal, key))
          end
        end
      end

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

      def resolve_city_code(postal)
        City.where(prefecture_code: postal.prefecture_code)
            .find { |c| c.full_name == postal.city_name }&.code
      end
    end
  end
end
