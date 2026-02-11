# frozen_string_literal: true

require "basho"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # DB自動切り替えテスト以外はメモリバックエンドを強制
  config.before(:each) do
    Basho.db = false unless self.class.metadata[:db]
  end

  config.after(:each) do
    Basho.reset_db_cache!
  end
end
