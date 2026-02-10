# frozen_string_literal: true

# 日本郵便 KEN_ALL.csv を basho形式の postal_codes/*.json に変換
# 使い方: ruby tasks/import/postal_codes.rb
#
# KEN_ALL.CSV のカラム:
# 0: 全国地方公共団体コード（5桁）
# 1: 旧郵便番号
# 2: 郵便番号（7桁）
# 3: 都道府県名カナ
# 4: 市区町村名カナ
# 5: 町域名カナ
# 6: 都道府県名
# 7: 市区町村名
# 8: 町域名
# 9-14: フラグ

require "csv"
require "json"

INPUT_PATH = "/tmp/ken_all/KEN_ALL.CSV"
OUTPUT_DIR = File.expand_path("../../data/postal_codes", __dir__)

abort "KEN_ALL.CSV が見つかりません: #{INPUT_PATH}" unless File.exist?(INPUT_PATH)

grouped = Hash.new { |h, k| h[k] = [] }
continuation = {}

CSV.foreach(INPUT_PATH, encoding: "Shift_JIS:UTF-8") do |row|
  postal_code = row[2]
  prefecture_code = row[0][0..1].to_i
  city_name = row[7]
  town = row[8]

  # 特殊な町域名は空にする
  town = "" if town == "以下に掲載がない場合"
  town = "" if town.end_with?("の次に番地がくる場合")

  # 複数行にまたがる町域名の結合
  if continuation[postal_code]
    continuation[postal_code][:town] += town
    unless town.include?("）")
      next # まだ閉じ括弧が来ていない、継続
    end

    # 括弧が閉じたので完了
    entry = continuation.delete(postal_code)
    prefix = postal_code[0..2]
    grouped[prefix] << entry
    next
  end

  # 括弧が開いて閉じていない場合、継続行として保持
  if town.include?("（") && !town.include?("）")
    continuation[postal_code] = {
      code: postal_code,
      prefecture_code: prefecture_code,
      city_name: city_name,
      town: town
    }
    next
  end

  # 括弧内を除去して簡潔にする
  town = town.gsub(/（.+?）/, "") if town.include?("（") && town.include?("）")

  prefix = postal_code[0..2]
  grouped[prefix] << {
    code: postal_code,
    prefecture_code: prefecture_code,
    city_name: city_name,
    town: town
  }
end

# 残りの continuation を追加
continuation.each do |postal_code, entry|
  prefix = postal_code[0..2]
  grouped[prefix] << entry
end

# 重複を除去してJSONに書き出し
total = 0
grouped.each do |prefix, entries|
  unique = entries.uniq { |e| [e[:code], e[:city_name], e[:town]] }
  output_path = File.join(OUTPUT_DIR, "#{prefix}.json")
  File.write(output_path, JSON.generate(unique))
  total += unique.size
end

puts "合計: #{total}件、#{grouped.size}ファイル"
