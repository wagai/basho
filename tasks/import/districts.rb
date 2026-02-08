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
    name = city["name"]

    # PostalCode側で完全一致があればスキップ（郡なし）
    next if postal_names.include?(name)

    # end_with? でマッチするものを探す（複数候補がある場合、郡名が最短のものが正解）
    candidates = postal_names.select { |pn| pn.end_with?(name) && pn != name }
    next if candidates.empty?

    # 最短の候補を選ぶ（"標津郡標津町" > "標津郡中標津町" にしない）
    match = candidates.min_by(&:length)
    district = match.delete_suffix(name)

    # 郡名は「〜郡」で終わるはず。そうでなければ誤マッチ
    unless district.end_with?("郡")
      puts "  スキップ（郡名でない）: #{pref_code} #{match} → district=#{district}"
      next
    end

    city["district"] = district
    updated_count += 1
  end

  File.write(path, JSON.pretty_generate(cities))
end

puts "郡名を #{updated_count} 件追加しました"
