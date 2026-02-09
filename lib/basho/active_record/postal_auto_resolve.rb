# frozen_string_literal: true

module Basho
  module ActiveRecord
    # 郵便番号変更時にbefore_saveで住所カラムを自動解決する
    module PostalAutoResolve
      MAPPING_KEYS = %i[prefecture city town prefecture_code city_code].freeze
      RESOLVERS = {
        prefecture: :prefecture_name,
        city: :city_name,
        town: :town,
        prefecture_code: :prefecture_code,
        city_code: :resolve_city_code
      }.freeze

      module_function

      def install(model_class, postal_column, mappings)
        validate_model!(model_class)

        postal_col = postal_column.to_s
        resolved = build_mappings(mappings)

        register_callback(model_class, postal_col, resolved)
      end

      def validate_model!(model_class)
        return if model_class.respond_to?(:before_save)

        raise Basho::Error, "#{model_class} does not support before_save callbacks"
      end

      def build_mappings(mappings)
        mappings.slice(*MAPPING_KEYS).transform_values(&:to_s).freeze
      end

      def register_callback(model_class, postal_col, resolved_mappings)
        model_class.before_save do
          next unless will_save_change_to_attribute?(postal_col)

          postal = PostalAutoResolve.resolve_postal(send(postal_col))

          resolved_mappings.each do |key, target_col|
            send(:"#{target_col}=", PostalAutoResolve.resolve_value(postal, key))
          end
        end
      end

      def resolve_postal(code)
        return nil unless code

        normalized = code.to_s.delete("-")
        return nil unless normalized.match?(/\A\d{7}\z/)

        Basho::PostalCode.find(normalized).first
      end

      def resolve_value(postal, key)
        return nil unless postal

        method_name = RESOLVERS[key]
        return nil unless method_name

        respond_to?(method_name, true) ? send(method_name, postal) : postal.public_send(method_name)
      end

      def resolve_city_code(postal)
        City.where(prefecture_code: postal.prefecture_code)
            .find { |c| c.full_name == postal.city_name }&.code
      end
    end
  end
end
