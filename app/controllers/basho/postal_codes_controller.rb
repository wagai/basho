# frozen_string_literal: true

module Basho
  # 郵便番号からTurbo Frame形式で住所を返すコントローラー
  class PostalCodesController < ActionController::Base
    def lookup
      @postal = PostalCode.find(params[:code])

      render layout: false
    end
  end
end
