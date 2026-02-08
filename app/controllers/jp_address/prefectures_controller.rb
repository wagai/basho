# frozen_string_literal: true

module JpAddress
  # 都道府県・市区町村のJSON APIコントローラー
  class PrefecturesController < ActionController::API
    def index
      prefectures = Prefecture.all.map { |p| { code: p.code, name: p.name } }
      render json: prefectures
    end

    def cities
      prefecture = find_prefecture
      return render json: [], status: :not_found unless prefecture

      cities = City.where(prefecture_code: prefecture.code).map { |c| { code: c.code, name: c.name } }
      render json: cities
    end

    private

    def find_prefecture
      code = params[:code].to_s
      return nil unless code.match?(/\A[1-9]\d?\z/)

      Prefecture.find(code.to_i)
    end
  end
end
