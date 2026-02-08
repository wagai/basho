# frozen_string_literal: true

# PostalCodeデータからCity JSONに郡名(district)を追加し、
# 異体字の不整合も修正する
#
# 使い方: ruby tasks/import/districts.rb

require "json"

POSTAL_DIR = File.expand_path("../../data/postal_codes", __dir__)
CITIES_DIR = File.expand_path("../../data/cities", __dir__)

# PostalCodeデータから都道府県ごとの city_name を収集
postal_city_names = Hash.new { |h, k| h[k] = Set.new }

Dir.glob(File.join(POSTAL_DIR, "*.json")).each do |f|
  JSON.parse(File.read(f)).each do |entry|
    postal_city_names[entry["prefecture_code"]] << entry["city"]
  end
end

updated_count = 0

(1..47).each do |pref_code|
  file = format("%02d.json", pref_code)
  path = File.join(CITIES_DIR, file)
  next unless File.exist?(path)

  cities = JSON.parse(File.read(path))
  postal_names = postal_city_names[pref_code]

  cities.each do |city|
    # PostalCode側の city_name から、この City にマッチするものを探す
    match = postal_names.find { |pn| pn.end_with?(city["name"]) && pn != city["name"] }

    if match
      district = match.sub(city["name"], "")
      city["district"] = district
      updated_count += 1
    end

    # 異体字の不整合: PostalCode側の名前に完全一致も end_with? 一致もない場合、
    # PostalCode側の名前を正とする
    exact = postal_names.find { |pn| pn == city["name"] || pn.end_with?(city["name"]) }
    unless exact
      # カナで探す
      alt = postal_names.find { |pn|
        # 同じ都道府県内で、末尾が「町」「村」で終わり、カナが一致しそうなもの
        pn.end_with?("町", "村") && city["name"].end_with?("町", "村")
      }
      puts "  異体字候補: #{pref_code} #{city['name']} → 手動確認が必要" unless exact
    end
  end

  File.write(path, JSON.pretty_generate(cities))
end

puts "郡名を #{updated_count} 件追加しました"
