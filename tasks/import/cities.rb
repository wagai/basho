# frozen_string_literal: true

# jp_local_gov gemのデータをbasho形式に変換
# 使い方: ruby tasks/import/cities.rb

require "json"

JP_LOCAL_GOV_DATA_DIR = File.expand_path(
  "~/.local/share/mise/installs/ruby/4.0.1/lib/ruby/gems/4.0.0/gems/jp_local_gov-1.0.0/data/json"
)
OUTPUT_DIR = File.expand_path("../../data/cities", __dir__)

(1..47).each do |prefecture_code|
  file = format("%02d.json", prefecture_code)
  source_path = File.join(JP_LOCAL_GOV_DATA_DIR, file)

  unless File.exist?(source_path)
    warn "スキップ: #{source_path} が見つかりません"
    next
  end

  source_data = JSON.parse(File.read(source_path), symbolize_names: true)

  cities = source_data.values.map do |entry|
    {
      code: entry[:code],
      prefecture_code: prefecture_code,
      name: entry[:city],
      name_kana: entry[:city_kana],
      capital: entry[:prefecture_capital] || false
    }
  end

  output_path = File.join(OUTPUT_DIR, file)
  File.write(output_path, JSON.pretty_generate(cities))
  puts "#{file}: #{cities.size}件"
end

puts "完了"
