# JpAddress

日本の住所データ（都道府県・市区町村・郵便番号・地方区分）を統一的に扱うRuby gem。郵便番号からの住所自動保存、都道府県・市区町村カスケードセレクト、Hotwire自動入力をサポート。

## 対応バージョン

- Ruby 3.2 / 3.3 / 3.4 / 4.0

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
pref.name_en       # => "Tokyo"
pref.name_kana     # => "トウキョウト"
pref.name_hiragana # => "とうきょうと"
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
city.name_kana        # => "チヨダク"
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
region.name_en          # => "Kanto"
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

### 郵便番号から住所を自動保存

`jp_address_postal`にマッピングオプションを渡すと、`before_save`で郵便番号から住所カラムを自動入力します。

```ruby
class User < ApplicationRecord
  include JpAddress
  jp_address_postal :postal_code,
    prefecture: :pref_name,
    city: :city_name,
    town: :town_name
end

user = User.new(postal_code: "154-0011")
user.save
user.pref_name  # => "東京都"
user.city_name  # => "世田谷区"
user.town_name  # => "上馬"
```

- `postal_code`が変更された時だけ解決を実行
- マッピングは部分指定可能（`prefecture:`だけでもOK）
- オプションなしの場合は従来通り`postal_address`メソッドのみ定義（後方互換）

### 郵便番号から住所検索（コントローラー例）

`PostalCode.find`を使えば、フレームワークを問わず自由にエンドポイントを作れます。

#### JSON API

```ruby
# app/controllers/postal_codes_controller.rb
class PostalCodesController < ApplicationController
  def lookup
    results = JpAddress::PostalCode.find(params[:code])

    render json: results.map { |r|
      { prefecture: r.prefecture_name, city: r.city_name, town: r.town }
    }
  end
end
```

#### Turbo Frame

```ruby
# app/controllers/postal_codes_controller.rb
class PostalCodesController < ApplicationController
  def lookup
    @postal = JpAddress::PostalCode.find(params[:code]).first
  end
end
```

```erb
<%# app/views/postal_codes/lookup.html.erb %>
<turbo-frame id="postal-result">
  <% if @postal %>
    <span data-prefecture="<%= @postal.prefecture_name %>"
          data-city="<%= @postal.city_name %>"
          data-town="<%= @postal.town %>"></span>
  <% end %>
</turbo-frame>
```

### 郵便番号自動入力（Hotwire Engine）

Turbo Frame + Stimulusによる住所自動入力をビルトインで提供するRails Engineです。自前でコントローラーを書かずに使えます。

#### セットアップ

```ruby
# config/application.rb
require "jp_address/engine"
```

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

#### 動作の流れ

1. ユーザーが郵便番号を入力（7桁）
2. 300msデバウンス後、Turbo Frameでサーバーに問い合わせ
3. サーバーが住所データ付きのTurbo Frameを返却
4. Stimulusが都道府県・市区町村・町域フィールドを自動入力

### 都道府県・市区町村カスケードセレクト（Hotwire Engine）

都道府県を選択すると、対応する市区町村がJSON APIで動的に読み込まれるカスケードセレクトです。

#### JSON APIエンドポイント

Engine をマウントすると以下のエンドポイントが利用可能になります。

```
GET /jp_address/prefectures          # => [{"code":1,"name":"北海道"}, ...]
GET /jp_address/prefectures/13/cities # => [{"code":"131016","name":"千代田区"}, ...]
```

#### フォームでの使い方

```erb
<%= form_with(model: @shop) do |f| %>
  <div data-controller="jp-address--cascade-select"
       data-jp-address--cascade-select-prefectures-url-value="<%= jp_address.prefectures_path %>"
       data-jp-address--cascade-select-cities-url-template-value="<%= jp_address.cities_prefecture_path(':code') %>">

    <select data-jp-address--cascade-select-target="prefecture"
            data-action="change->jp-address--cascade-select#prefectureChanged">
      <option value="">都道府県を選択</option>
    </select>

    <select data-jp-address--cascade-select-target="city">
      <option value="">市区町村を選択</option>
    </select>
  </div>
<% end %>
```

`jp_address_cascade_data`ヘルパーを使うとdata属性を簡潔に書けます。

```erb
<div <%= tag.attributes(data: jp_address_cascade_data) %>>
  ...
</div>
```

#### 動作の流れ

1. ページ読み込み時、都道府県セレクトが空ならAPIから47件を取得
2. 都道府県を選択すると、市区町村セレクトをAPIから再構築
3. 都道府県を変更すると、市区町村セレクトがリセットされ再取得

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
