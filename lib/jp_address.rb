# frozen_string_literal: true

require_relative "jp_address/version"
require_relative "jp_address/data/loader"
require_relative "jp_address/region"
require_relative "jp_address/prefecture"
require_relative "jp_address/code_validator"
require_relative "jp_address/city"
require_relative "jp_address/postal_code"
require_relative "jp_address/active_record/base"

module JpAddress
  class Error < StandardError; end

  def self.included(base)
    base.extend ActiveRecord::Base
  end
end
