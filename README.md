# Basho

日本の住所データ（都道府県・市区町村・郵便番号・地方区分）を統一的に扱うRuby gem。

## なぜ作ったか

日本の住所まわりは扱いが面倒です。

- 郵便番号から住所を引きたいだけなのに、CSVを自前でパースしてDBに入れる必要がある
- 都道府県・市区町村のマスタデータを持つためにマイグレーションを書かされる
- 郵便番号の自動入力、都道府県→市区町村の連動セレクトは毎回同じコードを書いている
- 既存gemはRails依存が強い、データが古い、Hotwire非対応、など

Bashoはこれらをまとめて解決します。

- **DBマイグレーション不要** — 全データをJSON同梱。`gem install`だけで使える
- **ActiveRecord統合** — `include Basho` + 1行のマクロで郵便番号→住所の自動保存
- **Hotwire対応** — 郵便番号自動入力・カスケードセレクトをビルトインEngine提供
- **軽量** — `Data.define`によるイミュータブルモデル、遅延読み込み、外部依存なし

## 対応バージョン

- Ruby 3.2 / 3.3 / 3.4 / 4.0

## インストール

```ruby
# Gemfile
gem "basho"
```

```bash
bundle install
```

## クイックスタート

### 郵便番号から住所を引く

```ruby
postal = Basho::PostalCode.find("154-0011").first
postal.prefecture_name  # => "東京都"
postal.city_name        # => "世田谷区"
postal.town             # => "上馬"
```

### モデルで郵便番号→住所を自動保存

```ruby
class User < ApplicationRecord
  include Basho
  basho_postal :postal_code,
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

### 都道府県・市区町村を検索

```ruby
Basho::Prefecture.find(13).name           # => "東京都"
Basho::Prefecture.where(region: "関東")    # => 7件
Basho::City.find("131016").name            # => "千代田区"
```

## 使い方

### Prefecture（都道府県）

```ruby
Basho::Prefecture.find(13)             # コードで検索
Basho::Prefecture.find(name: "東京都")  # 名前で検索
Basho::Prefecture.all                   # 全47件
Basho::Prefecture.where(region: "関東") # 地方で絞り込み

pref = Basho::Prefecture.find(13)
pref.code          # => 13
pref.name          # => "東京都"
pref.name_en       # => "Tokyo"
pref.name_kana     # => "トウキョウト"
pref.name_hiragana # => "とうきょうと"
pref.type          # => "都"
pref.region        # => Region
pref.cities        # => Array<City>
pref.capital       # => City（県庁所在地）
```

### City（市区町村）

```ruby
Basho::City.find("131016")              # 自治体コードで検索
Basho::City.where(prefecture_code: 13)  # 都道府県で絞り込み
Basho::City.valid_code?("131016")       # チェックディジット検証

city = Basho::City.find("131016")
city.code             # => "131016"
city.prefecture_code  # => 13
city.name             # => "千代田区"
city.name_kana        # => "チヨダク"
city.capital?         # => false
city.prefecture       # => Prefecture
```

### PostalCode（郵便番号）

```ruby
results = Basho::PostalCode.find("154-0011")  # 常にArrayを返す
results = Basho::PostalCode.find("1540011")    # ハイフンなしも可

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
Basho::Region.all                # 8地方
Basho::Region.find("関東")       # 名前で検索

region = Basho::Region.find("関東")
region.name             # => "関東"
region.name_en          # => "Kanto"
region.prefectures      # => Array<Prefecture>
region.prefecture_codes # => [8, 9, 10, 11, 12, 13, 14]
```

## ActiveRecord統合

### 自治体コードから都道府県・市区町村を引く

```ruby
class Shop < ApplicationRecord
  include Basho
  basho :local_gov_code
end

shop.prefecture   # => Prefecture
shop.city         # => City
shop.full_address # => "東京都千代田区"
```

### 郵便番号から住所文字列を取得

```ruby
class Shop < ApplicationRecord
  include Basho
  basho_postal :postal_code
end

shop.postal_address # => "東京都世田谷区上馬"
```

### 郵便番号から住所カラムを自動保存

`basho_postal`にマッピングオプションを渡すと、`before_save`で郵便番号から住所カラムを自動入力します。

```ruby
class User < ApplicationRecord
  include Basho
  basho_postal :postal_code,
    prefecture: :pref_name,
    city: :city_name,
    town: :town_name
end
```

- `postal_code`が変更された時だけ解決を実行
- マッピングは部分指定可能（`prefecture:`だけでもOK）
- オプションなしの場合は`postal_address`メソッドのみ定義（後方互換）

## Hotwire Engine

Turbo Frame + Stimulusによる住所自動入力・カスケードセレクトをビルトインで提供するRails Engineです。自前でコントローラーを書かずに使えます。

### セットアップ

```ruby
# config/application.rb
require "basho/engine"
```

```ruby
# config/routes.rb
mount Basho::Engine, at: "/basho"
```

### 郵便番号自動入力

郵便番号を入力すると都道府県・市区町村・町域フィールドを自動入力します。

```erb
<%= form_with(model: @shop) do |f| %>
  <div data-controller="basho--auto-fill"
       data-basho--auto-fill-url-value="<%= basho.postal_code_lookup_path %>">

    <%= f.text_field :postal_code,
          data: { action: "input->basho--auto-fill#lookup",
                  "basho--auto-fill-target": "input" } %>

    <turbo-frame id="basho-result"
                 data-basho--auto-fill-target="frame"></turbo-frame>

    <%= f.text_field :prefecture,
          data: { "basho--auto-fill-target": "prefecture" } %>
    <%= f.text_field :city,
          data: { "basho--auto-fill-target": "city" } %>
    <%= f.text_field :town,
          data: { "basho--auto-fill-target": "town" } %>
  </div>
<% end %>
```

1. ユーザーが郵便番号を入力（7桁）
2. 300msデバウンス後、Turbo Frameでサーバーに問い合わせ
3. Stimulusが都道府県・市区町村・町域フィールドを自動入力

### 都道府県・市区町村カスケードセレクト

都道府県を選択すると、対応する市区町村がJSON APIで動的に読み込まれます。

```erb
<%= form_with(model: @shop) do |f| %>
  <div data-controller="basho--cascade-select"
       data-basho--cascade-select-prefectures-url-value="<%= basho.prefectures_path %>"
       data-basho--cascade-select-cities-url-template-value="<%= basho.cities_prefecture_path(':code') %>">

    <select data-basho--cascade-select-target="prefecture"
            data-action="change->basho--cascade-select#prefectureChanged">
      <option value="">都道府県を選択</option>
    </select>

    <select data-basho--cascade-select-target="city">
      <option value="">市区町村を選択</option>
    </select>
  </div>
<% end %>
```

`basho_cascade_data`ヘルパーでdata属性を簡潔に書けます。

```erb
<div <%= tag.attributes(data: basho_cascade_data) %>>
  ...
</div>
```

1. ページ読み込み時、都道府県セレクトが空ならAPIから47件を取得
2. 都道府県を選択すると、市区町村セレクトをAPIから再構築
3. 都道府県を変更すると、市区町村セレクトがリセットされ再取得

### JSON APIエンドポイント

Engineをマウントすると以下のエンドポイントが利用可能になります。

```
GET /basho/prefectures           # => [{"code":1,"name":"北海道"}, ...]
GET /basho/prefectures/13/cities  # => [{"code":"131016","name":"千代田区"}, ...]
GET /basho/postal_codes/lookup?code=1540011  # => Turbo Frame HTML
```

## Engine不要の場合

Engineを使わず、`PostalCode.find`で自由にエンドポイントを作ることもできます。

```ruby
# JSON API
class PostalCodesController < ApplicationController
  def lookup
    results = Basho::PostalCode.find(params[:code])

    render json: results.map { |r|
      { prefecture: r.prefecture_name, city: r.city_name, town: r.town }
    }
  end
end
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
git clone https://github.com/wagai/basho.git
cd basho
bin/setup
bundle exec rspec
```

## ライセンス

MIT License
