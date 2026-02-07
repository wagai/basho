# frozen_string_literal: true

module JpAddress
  class PostalCodesController < ActionController::Base
    def lookup
      code = params[:code].to_s.delete("-")
      @postal = PostalCode.find(code).first if code.match?(/\A\d{7}\z/)

      render layout: false
    end
  end
end
