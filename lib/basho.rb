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

  @db_mutex = Mutex.new

  # basho_prefectures テーブルが存在すればDB経由で検索する
  def self.db?
    return @db if defined?(@db)

    @db_mutex.synchronize do
      return @db if defined?(@db)

      @db = defined?(::ActiveRecord::Base) &&
            ::ActiveRecord::Base.connection.table_exists?("basho_prefectures")
      require "basho/db" if @db
      @db
    end
  rescue ::ActiveRecord::ConnectionNotEstablished, ::ActiveRecord::NoDatabaseError
    @db = false
  end

  # テスト用: DB検出キャッシュをリセット
  def self.reset_db_cache!
    remove_instance_variable(:@db) if defined?(@db)
    Prefecture.reset_cache! if Prefecture.respond_to?(:reset_cache!)
  end

  # テスト用: バックエンドを強制指定
  def self.db=(value)
    @db = value
    require "basho/db" if value
  end

  def self.included(base)
    base.extend ActiveRecord::Base
  end
end
