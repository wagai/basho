# frozen_string_literal: true

require_relative "jp_address/version"
require_relative "jp_address/data/loader"
require_relative "jp_address/region"
require_relative "jp_address/prefecture"
require_relative "jp_address/code_validator"
require_relative "jp_address/city"
require_relative "jp_address/postal_code"
require_relative "jp_address/active_record/base"

# 日本の住所データ（都道府県・市区町村・郵便番号・地方区分）を統一的に扱うgem
module JpAddress
  class Error < StandardError; end

  def self.included(base)
    base.extend ActiveRecord::Base
  end
end
