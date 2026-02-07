# JpAddress

日本の住所データ（都道府県・市区町村・郵便番号・地方区分）を統一的に扱うRuby gem。

## インストール

```ruby
# Gemfile
gem "jp_address"
```

```bash
bundle install
```

## 使い方

### Prefecture（都道府県）

```ruby
JpAddress::Prefecture.find(13)             # コードで検索
JpAddress::Prefecture.find(name: "東京都")  # 名前で検索
JpAddress::Prefecture.all                   # 全47件
JpAddress::Prefecture.where(region: "関東") # 地方で絞り込み

pref = JpAddress::Prefecture.find(13)
pref.code       # => 13
pref.name       # => "東京都"
pref.name_e     # => "Tokyo"
pref.name_k     # => "トウキョウト"
pref.name_h     # => "とうきょうと"
pref.type       # => "都"
pref.region     # => Region
pref.cities     # => Array<City>
pref.capital    # => City（県庁所在地）
```

### City（市区町村）

```ruby
JpAddress::City.find("131016")                  # 自治体コードで検索
JpAddress::City.where(prefecture_code: 13)      # 都道府県で絞り込み
JpAddress::City.valid_code?("131016")           # チェックディジット検証

city = JpAddress::City.find("131016")
city.code             # => "131016"
city.prefecture_code  # => 13
city.name             # => "千代田区"
city.name_k           # => "チヨダク"
city.capital?         # => false
city.prefecture       # => Prefecture
```

### PostalCode（郵便番号）

```ruby
results = JpAddress::PostalCode.find("154-0011")  # 常にArrayを返す
results = JpAddress::PostalCode.find("1540011")    # ハイフンなしも可

postal = results.first
postal.code              # => "1540011"
postal.formatted_code    # => "154-0011"
postal.prefecture_code   # => 13
postal.prefecture_name   # => "東京都"
postal.city_name         # => "世田谷区"
postal.town              # => "上馬"
postal.prefecture        # => Prefecture
```

### Region（地方区分）

```ruby
JpAddress::Region.all                # 8地方
JpAddress::Region.find("関東")       # 名前で検索

region = JpAddress::Region.find("関東")
region.name             # => "関東"
region.name_e           # => "Kanto"
region.prefectures      # => Array<Prefecture>
region.prefecture_codes # => [8, 9, 10, 11, 12, 13, 14]
```

### ActiveRecord統合

```ruby
class Shop < ApplicationRecord
  include JpAddress
  jp_address :local_gov_code
  jp_address_postal :postal_code
end

shop.prefecture   # => Prefecture
shop.city         # => City
shop.full_address # => "東京都千代田区"
shop.postal_address # => "東京都世田谷区上馬"
```

### 郵便番号自動入力（Hotwire）

Rails 7+アプリでTurbo Frame + Stimulusによる住所自動入力を提供します。

#### セットアップ

```ruby
# config/routes.rb
mount JpAddress::Engine, at: "/jp_address"
```

#### フォームでの使い方

```erb
<%= form_with(model: @shop) do |f| %>
  <div data-controller="jp-address--auto-fill"
       data-jp-address--auto-fill-url-value="<%= jp_address.postal_code_lookup_path %>">

    <%= f.text_field :postal_code,
          data: { action: "input->jp-address--auto-fill#lookup",
                  "jp-address--auto-fill-target": "input" } %>

    <turbo-frame id="jp-address-result"
                 data-jp-address--auto-fill-target="frame"></turbo-frame>

    <%= f.text_field :prefecture,
          data: { "jp-address--auto-fill-target": "prefecture" } %>
    <%= f.text_field :city,
          data: { "jp-address--auto-fill-target": "city" } %>
    <%= f.text_field :town,
          data: { "jp-address--auto-fill-target": "town" } %>
  </div>
<% end %>
```

`jp_address_autofill_frame_tag`ヘルパーでTurbo Frameタグを生成できます:

```erb
<%= jp_address_autofill_frame_tag %>
<%# => <turbo-frame id="jp-address-result" data-jp-address--auto-fill-target="frame"></turbo-frame> %>
```

#### 動作の流れ

1. ユーザーが郵便番号を入力（7桁）
2. 300msデバウンス後、Turbo Frameでサーバーに問い合わせ
3. サーバーが住所データ付きのTurbo Frameを返却
4. Stimulusが都道府県・市区町村・町域フィールドを自動入力

#### オプション

デバウンス間隔の変更:

```erb
<div data-controller="jp-address--auto-fill"
     data-jp-address--auto-fill-url-value="<%= jp_address.postal_code_lookup_path %>"
     data-jp-address--auto-fill-delay-value="500">
```

## データソース

| データ | ソース | 更新頻度 |
|--------|--------|----------|
| 都道府県 | 総務省 JIS X 0401 | ほぼ変わらない |
| 市区町村 | 総務省 全国地方公共団体コード | 年に数回 |
| 郵便番号 | 日本郵便 KEN_ALL.csv | 月次（GitHub Actions自動更新） |
| 地方区分 | 8地方（ハードコード） | 変わらない |

## 開発

```bash
git clone https://github.com/wagai/jp_address.git
cd jp_address
bin/setup
bundle exec rspec
```

## ライセンス

MIT License
