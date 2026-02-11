# frozen_string_literal: true

module Basho
  module DB
    class Prefecture < ::ActiveRecord::Base
      self.table_name = "basho_prefectures"
      self.primary_key = "code"

      has_many :cities,
               class_name: "Basho::DB::City",
               foreign_key: :prefecture_code,
               inverse_of: :prefecture

      def type = prefecture_type
      def region = Region.find(region_name)
      def capital = capital_code && Basho::DB::City.find_by(code: capital_code)
    end
  end
end
