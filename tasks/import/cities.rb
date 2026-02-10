# frozen_string_literal: true

# 日本郵便 KEN_ALL.csv から basho形式の cities/*.json に変換
# 使い方: ruby tasks/import/cities.rb
#
# KEN_ALL.CSV のカラム:
# 0: 全国地方公共団体コード（5桁）
# 4: 市区町村名カナ（半角）
# 7: 市区町村名

require "csv"
require "json"
require_relative "../../lib/basho/code_validator"

INPUT_PATH = "/tmp/ken_all/KEN_ALL.CSV"
OUTPUT_DIR = File.expand_path("../../data/cities", __dir__)
PREFECTURES_PATH = File.expand_path("../../data/prefectures.json", __dir__)

abort "KEN_ALL.CSV が見つかりません: #{INPUT_PATH}" unless File.exist?(INPUT_PATH)

# 県庁所在地コードのセット
capital_codes = JSON.parse(File.read(PREFECTURES_PATH))
                    .to_set { |p| p["capital_code"] }

# KEN_ALL.CSV から市区町村を抽出（5桁コード → 1レコード）
ken_cities = {}

CSV.foreach(INPUT_PATH, encoding: "Shift_JIS:UTF-8") do |row|
  code5 = row[0]
  next if ken_cities.key?(code5)

  pref_code = code5[0..1].to_i
  name = row[7]
  kana = row[4].unicode_normalize(:nfkc)

  # 郡名・島名の分離
  # 郡に属するのは町・村のみ。「蒲郡市」のような市名に含まれる「郡」は対象外
  # 島: 三宅島三宅村、八丈島八丈町のような島嶼district
  district = nil
  if name.match?(/\A.+郡.+[町村]\z/)
    district, name = name.split("郡", 2)
    district = "#{district}郡"
    # 北群馬郡のように郡名自体に「グン」を含む場合があるため、末尾のグンで分割
    kana_pos = kana.rindex("グン")
    kana = kana[(kana_pos + 2)..] if kana_pos
  elsif name.match?(/\A.+島.+[町村]\z/)
    district, name = name.split("島", 2)
    district = "#{district}島"
    kana_pos = kana.rindex("ジマ") || kana.rindex("シマ")
    kana = kana[(kana_pos + 2)..] if kana_pos
  end

  code6 = "#{code5}#{Basho::CodeValidator.compute_check_digit(code5)}"

  ken_cities[code5] = {
    code: code6,
    prefecture_code: pref_code,
    name: name,
    capital: capital_codes.include?(code6),
    name_kana: kana,
    district: district
  }
end

# KEN_ALLにない既存エントリを保存（政令指定都市の親コード・北方領土）
preserved = Hash.new { |h, k| h[k] = [] }

(1..47).each do |pref_code|
  path = File.join(OUTPUT_DIR, format("%02d.json", pref_code))
  next unless File.exist?(path)

  JSON.parse(File.read(path), symbolize_names: true).each do |city|
    code5 = city[:code][0..4]
    next if ken_cities.key?(code5)

    preserved[pref_code] << city
  end
end

# 都道府県ごとにJSON出力
total = 0
preserved_total = 0

(1..47).each do |pref_code|
  cities = ken_cities.values
                     .select { |c| c[:prefecture_code] == pref_code }
                     .concat(preserved[pref_code])
                     .sort_by { |c| c[:code] }
  cities = cities.map do |c|
    entry = {
      code: c[:code],
      prefecture_code: c[:prefecture_code],
      name: c[:name],
      capital: c[:capital] || false,
      name_kana: c[:name_kana]
    }
    entry[:district] = c[:district] if c[:district]&.match?(/[郡島]\z/)
    entry
  end

  file = format("%02d.json", pref_code)
  File.write(File.join(OUTPUT_DIR, file), JSON.pretty_generate(cities))
  preserved_count = preserved[pref_code].size
  preserved_total += preserved_count
  total += cities.size
  suffix = preserved_count.positive? ? "（うち既存保持: #{preserved_count}件）" : ""
  puts "#{file}: #{cities.size}件#{suffix}"
end

puts "合計: #{total}件（KEN_ALL: #{ken_cities.size}件 + 既存保持: #{preserved_total}件）"
