# frozen_string_literal: true

module Basho
  # 郵便番号からTurbo Frame形式で住所を返すコントローラー
  class PostalCodesController < ActionController::Base
    def lookup
      code = params[:code].to_s.delete("-")
      @postal = PostalCode.find(code) if code.match?(/\A\d{7}\z/)

      render layout: false
    end
  end
end
