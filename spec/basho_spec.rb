# frozen_string_literal: true

RSpec.describe Basho do
  it "バージョン番号がある" do
    expect(Basho::VERSION).not_to be_nil
  end
end
