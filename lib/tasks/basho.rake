# frozen_string_literal: true

namespace :basho do
  desc "basho_prefectures / basho_cities テーブルにデータを投入"
  task seed: :environment do
    require "basho/db"

    counts = Basho::DB.seed!
    puts "basho:seed 完了 — 都道府県: #{counts[:prefectures]}件, 市区町村: #{counts[:cities]}件"
  end
end
