# frozen_string_literal: true

require_relative "basho/version"
require_relative "basho/data/loader"
require_relative "basho/region"
require_relative "basho/prefecture"
require_relative "basho/code_validator"
require_relative "basho/city"
require_relative "basho/postal_code"
require_relative "basho/active_record/base"
require_relative "basho/engine" if defined?(Rails::Engine)

# 日本の住所データ（都道府県・市区町村・郵便番号・地方区分）を統一的に扱うgem
module Basho
  class Error < StandardError; end

  def self.included(base)
    base.extend ActiveRecord::Base
  end
end
