[English](README.md)

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
- **フレームワーク非依存** — 素のRuby、Sinatra、Rails API only、どこでも動く
- **ActiveRecord統合** — `include Basho` + 1行のマクロで郵便番号→住所の自動保存（オプション）
- **Hotwire対応** — Turbo Frame + Stimulusによる郵便番号自動入力をビルトインEngine提供（オプション）
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
postal = Basho::PostalCode.find("154-0011")
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
postal = Basho::PostalCode.find("154-0011")   # => PostalCode or nil
postal = Basho::PostalCode.find("1540011")    # ハイフンなしも可
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
Basho::Region.all                # 9地方
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

Turbo Frame + Stimulusによる郵便番号自動入力をビルトインで提供するRails Engineです。

### セットアップ

```ruby
# config/routes.rb
mount Basho::Engine, at: "/basho"
```

### 郵便番号自動入力

7桁の郵便番号を入力すると、都道府県・市区町村・町域フィールドを自動入力します。

```erb
<%= form_with(model: @shop) do |f| %>
  <div data-controller="basho--auto-fill"
       data-basho--auto-fill-url-value="<%= basho.postal_code_lookup_path %>">

    <%= f.text_field :postal_code,
          data: { action: "input->basho--auto-fill#lookup",
                  "basho--auto-fill-target": "input" } %>

    <turbo-frame id="basho-result"
                 data-basho--auto-fill-target="frame"
                 data-action="turbo:frame-load->basho--auto-fill#fill"></turbo-frame>

    <div data-basho--auto-fill-target="fields" hidden>
      <%= f.text_field :prefecture, disabled: true,
            data: { "basho--auto-fill-target": "prefecture" } %>
      <%= f.text_field :city, disabled: true,
            data: { "basho--auto-fill-target": "city" } %>
      <%= f.text_field :town, disabled: true,
            data: { "basho--auto-fill-target": "town" } %>
    </div>
  </div>
<% end %>
```

1. ユーザーが7桁の郵便番号を入力
2. Turbo Frameでサーバーに問い合わせ
3. Stimulusが都道府県・市区町村・町域フィールドを自動入力して表示
4. 郵便番号をクリア・変更するとフィールドは非表示に

`fields`ターゲットはオプションです。なければフィールドは常に表示され、値のクリアのみ行います。

`basho_autofill_frame_tag`ヘルパーで`<turbo-frame>`タグを簡潔に書けます：

```erb
<%= basho_autofill_frame_tag %>
```

### 都道府県・市区町村カスケードセレクト

Bashoはデータを提供します。UIはアプリ側でTurbo Frameを使って実装してください。

```ruby
# app/controllers/cities_controller.rb
class CitiesController < ApplicationController
  def index
    @cities = Basho::City.where(prefecture_code: params[:prefecture_code].to_i)
  end
end
```

```erb
<%# app/views/cities/index.html.erb %>
<turbo-frame id="city-select">
  <%= f.select :city_code,
        @cities.map { |c| [c.name, c.code] },
        { include_blank: "市区町村を選択" } %>
</turbo-frame>
```

```erb
<%# フォーム内 %>
<%= f.select :prefecture_code,
      Basho::Prefecture.all.map { |p| [p.name, p.code] },
      { include_blank: "都道府県を選択" },
      data: { action: "change->auto-submit#submit",
              turbo_frame: "city-select" } %>

<turbo-frame id="city-select">
  <%= f.select :city_code, [], include_blank: "市区町村を選択" %>
</turbo-frame>
```

HTMLとスタイリングの自由度はアプリ側にあります。

## Hotwireなしでの利用

データAPIとActiveRecord統合はHotwireなしで動きます。Engineをマウントしなければ、ルーティングもStimulus controllerも読み込まれません。

```ruby
# データAPIだけ — どのRubyアプリでも動く
require "basho"

Basho::PostalCode.find("154-0011").town         # => "上馬"
Basho::Prefecture.find(13).name                 # => "東京都"
Basho::City.where(prefecture_code: 13)          # => Array<City>
```

```ruby
# ActiveRecord統合 — Hotwireの有無に関係なく、どのRailsアプリでも動く
class Shop < ApplicationRecord
  include Basho
  basho_postal :postal_code, city_code: :city_code, town: :town
end
```

## データソース

| データ | ソース | 更新頻度 |
|--------|--------|----------|
| 都道府県 | 総務省 JIS X 0401 | ほぼ変わらない |
| 市区町村 | 総務省 全国地方公共団体コード | 年に数回 |
| 郵便番号 | 日本郵便 KEN_ALL.csv | 月次（GitHub Actions自動更新） |
| 地方区分 | 9地方（ハードコード） | 変わらない |

## 開発

```bash
git clone https://github.com/wagai/basho.git
cd basho
bin/setup
bundle exec rspec
```

## ライセンス

MIT License
