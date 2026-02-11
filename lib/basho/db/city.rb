# frozen_string_literal: true

module Basho
  module DB
    class City < ::ActiveRecord::Base
      self.table_name = "basho_cities"
      self.primary_key = "code"

      belongs_to :prefecture,
                 class_name: "Basho::DB::Prefecture",
                 foreign_key: :prefecture_code,
                 inverse_of: :cities

      def full_name
        district ? "#{district}#{name}" : name
      end
    end
  end
end
