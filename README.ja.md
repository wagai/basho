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

## 特徴

- **DBマイグレーション不要** -- 全データをJSON同梱。`gem install`だけで使える
- **オプションDBバックエンド** -- テーブル生成でJOINや外部キー制約に対応。APIは自動で切り替わる
- **フレームワーク非依存** -- 素のRuby、Sinatra、Rails API only、どこでも動く
- **ActiveRecord統合** -- `include Basho` + 1行のマクロで郵便番号→住所の自動保存
- **Hotwire対応** -- Turbo Frame + Stimulusによる郵便番号自動入力をビルトインEngine提供
- **軽量** -- `Data.define`によるイミュータブルモデル、遅延読み込み、外部依存なし

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
# クラスメソッド
Basho::Prefecture.find(13)                 # コードで検索（Integer）
Basho::Prefecture.find(name: "東京都")      # 日本語名で検索
Basho::Prefecture.find(name_en: "Tokyo")   # 英語名で検索
Basho::Prefecture.all                      # 全47件
Basho::Prefecture.where(region: "関東")     # 地方名で絞り込み
```

```ruby
# インスタンスメソッド / メンバー
pref = Basho::Prefecture.find(13)
pref.code          # => 13            (Integer)
pref.name          # => "東京都"       (String)
pref.name_en       # => "Tokyo"       (String)
pref.name_kana     # => "トウキョウト"  (String, カタカナ)
pref.name_hiragana # => "とうきょうと"  (String, ひらがな)
pref.region_name   # => "関東"         (String)
pref.type          # => "都"           (String: "都" / "道" / "府" / "県")
pref.capital_code  # => "131016"       (String, 6桁自治体コード)
pref.region        # => Basho::Region
pref.cities        # => Array<Basho::City>
pref.capital       # => Basho::City（県庁所在地）
```

### City（市区町村）

```ruby
# クラスメソッド
Basho::City.find("131016")              # 6桁自治体コードで検索（String）
Basho::City.where(prefecture_code: 13)  # 都道府県コードで絞り込み（Integer）
Basho::City.valid_code?("131016")       # JIS X 0401 チェックディジット検証
```

```ruby
# インスタンスメソッド / メンバー
city = Basho::City.find("131016")
city.code             # => "131016"    (String, 6桁)
city.prefecture_code  # => 13          (Integer)
city.name             # => "千代田区"   (String)
city.name_kana        # => "チヨダク"   (String, カタカナ)
city.district         # => nil         (String or nil, 例: "島尻郡")
city.capital          # => false       (Boolean, 生のメンバー)
city.capital?         # => false       (Boolean, 県庁所在地か?)
city.full_name        # => "千代田区"   (String, 郡名がある場合は先頭に付与)
city.prefecture       # => Basho::Prefecture
```

`district`は郡に属する町村にのみ設定されます。例:

```ruby
city = Basho::City.find("473821")
city.name       # => "八重瀬町"
city.district   # => "島尻郡"
city.full_name  # => "島尻郡八重瀬町"
```

### PostalCode（郵便番号）

`find`は単一の`PostalCode`または`nil`を返します。`where`は`Array`を返します（共有郵便番号の場合、複数件返ることがあります）。

```ruby
# クラスメソッド
Basho::PostalCode.find("154-0011")         # => PostalCode or nil（最初の1件）
Basho::PostalCode.find("1540011")          # ハイフンなしも可
Basho::PostalCode.where(code: "154-0011")  # => Array<PostalCode>
```

```ruby
# インスタンスメソッド / メンバー
postal = Basho::PostalCode.find("154-0011")
postal.code              # => "1540011"   (String, 7桁, ハイフンなし)
postal.formatted_code    # => "154-0011"  (String, ハイフン付き)
postal.prefecture_code   # => 13          (Integer)
postal.city_name         # => "世田谷区"   (String)
postal.town              # => "上馬"       (String)
postal.prefecture_name   # => "東京都"     (String)
postal.prefecture        # => Basho::Prefecture
```

### Region（地方区分）

9地方: 北海道、東北、関東、中部、近畿、中国、四国、九州、沖縄。

```ruby
# クラスメソッド
Basho::Region.all                # => 9地方の配列
Basho::Region.find("関東")       # 日本語名で検索
Basho::Region.find("Kanto")     # 英語名で検索
```

```ruby
# インスタンスメソッド / メンバー
region = Basho::Region.find("関東")
region.name             # => "関東"     (String)
region.name_en          # => "Kanto"   (String)
region.prefecture_codes # => [8, 9, 10, 11, 12, 13, 14]  (Array<Integer>)
region.prefectures      # => Array<Basho::Prefecture>
```

## ActiveRecord統合

モデルに`include Basho`を追加すると、`basho`と`basho_postal`マクロが使えるようになります。

### 自治体コードから都道府県・市区町村を引く

```ruby
class Shop < ApplicationRecord
  include Basho
  basho :local_gov_code
end

shop.city         # => Basho::City
shop.prefecture   # => Basho::Prefecture
shop.full_address # => "東京都千代田区"
```

`basho :column`は3つのインスタンスメソッドを定義します:

| メソッド | 戻り値 |
|---------|--------|
| `city` | カラム値で検索した`Basho::City` |
| `prefecture` | `city.prefecture`経由の`Basho::Prefecture` |
| `full_address` | `"#{prefecture.name}#{city.name}"` または `nil` |

### 郵便番号から住所文字列を取得

```ruby
class Shop < ApplicationRecord
  include Basho
  basho_postal :postal_code
end

shop.postal_address # => "東京都世田谷区上馬"
```

`basho_postal :column`（マッピングオプションなし）は`postal_address`メソッドを定義します。戻り値は`"#{prefecture_name}#{city_name}#{town}"`または`nil`です。

### 郵便番号から住所カラムを自動保存

`basho_postal`にマッピングオプションを渡すと、`before_save`コールバックを登録し、郵便番号カラムの変更時に住所カラムを自動入力します。

```ruby
class User < ApplicationRecord
  include Basho
  basho_postal :postal_code,
    prefecture: :pref_name,
    city: :city_name,
    town: :town_name
end
```

利用可能なマッピングキー:

| キー | 解決される値 |
|------|-------------|
| `prefecture:` | 都道府県名（例: "東京都"） |
| `city:` | 市区町村名（例: "世田谷区"） |
| `town:` | 町域名（例: "上馬"） |
| `prefecture_code:` | 都道府県コード（例: 13） |
| `city_code:` | 6桁自治体コード（例: "131130"） |

- 解決は郵便番号カラムが保存時に変更される場合のみ実行
- マッピングは部分指定可能（`prefecture:`だけでもOK）
- `postal_address`メソッドはマッピングオプションの有無に関わらず常に定義される

## Hotwire Engine

Turbo Frame + Stimulusによる郵便番号自動入力をビルトインで提供するRails Engineです。

### セットアップ

Engineをルーティングにマウントします:

```ruby
# config/routes.rb
mount Basho::Engine, at: "/basho"
```

Engineが提供するルート:

| メソッド | パス | コントローラー#アクション |
|---------|------|------------------------|
| GET | `/basho/postal_codes/lookup?code=1540011` | `Basho::PostalCodesController#lookup` |

Stimulusコントローラーとフォームヘルパーはimportmapと`ActionView`のinitializerにより自動登録されます。

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

動作の流れ:

1. ユーザーが7桁の郵便番号を入力
2. Turbo FrameでEngineのlookupエンドポイントに問い合わせ
3. Stimulusが都道府県・市区町村・町域フィールドを自動入力し、`fields`コンテナを表示
4. 郵便番号をクリア・変更するとフィールドは非表示に

`fields`ターゲットはオプションです。なければフィールドは常に表示され、値のクリアのみ行います。

`basho_autofill_frame_tag`ヘルパーで`<turbo-frame>`タグを簡潔に書けます:

```erb
<%= basho_autofill_frame_tag %>
```

これは以下をレンダリングします:

```html
<turbo-frame id="basho-result"
             data-basho--auto-fill-target="frame"
             data-action="turbo:frame-load->basho--auto-fill#fill"></turbo-frame>
```

#### Stimulusコントローラーのターゲットとバリュー

| 種類 | 名前 | 説明 |
|------|------|------|
| Value | `url` (String) | lookupエンドポイントのURL（必須） |
| Target | `input` | 郵便番号入力フィールド |
| Target | `frame` | サーバーレスポンス用Turbo Frame |
| Target | `prefecture` | 都道府県出力フィールド |
| Target | `city` | 市区町村出力フィールド |
| Target | `town` | 町域出力フィールド |
| Target | `fields` | 表示/非表示コンテナ（オプション） |

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
# データAPIだけ -- どのRubyアプリでも動く
require "basho"

Basho::PostalCode.find("154-0011").town         # => "上馬"
Basho::Prefecture.find(13).name                 # => "東京都"
Basho::City.where(prefecture_code: 13)          # => Array<City>
```

```ruby
# ActiveRecord統合 -- Hotwireの有無に関係なく、どのRailsアプリでも動く
class Shop < ApplicationRecord
  include Basho
  basho_postal :postal_code, city_code: :city_code, town: :town
end
```

## DBバックエンド（オプション）

デフォルトではBashoは同梱のJSONファイルからデータを読み込みます。DB不要です。JOINや外部キー制約が必要な場合、または自前のテーブルから`basho_prefectures` / `basho_cities`を参照したい場合は、オプションでDBテーブルを生成できます。

### セットアップ

```bash
rails generate basho:install_tables
rails db:migrate
rails basho:seed
```

2つのテーブルが作成されます:

| テーブル | 主キー | 件数 |
|---------|--------|------|
| `basho_prefectures` | `code` (integer) | 47 |
| `basho_cities` | `code` (string, 6桁) | 約1,900 |

### 透過的な自動切り替え

テーブルが存在すれば、公開API（`Basho::Prefecture.find`、`Basho::City.where`等）は自動的にDBバックエンドを使います。**コード変更は不要です。**

```ruby
# DBテーブルの有無に関わらず同じコードで動く
Basho::Prefecture.find(13).name           # => "東京都"
Basho::City.find("131016").full_name      # => "千代田区"
Basho::City.where(prefecture_code: 13)    # => Array
```

検出は初回アクセス時に1度だけ行われ、プロセスの生存期間中キャッシュされます。

### 自前テーブルからの外部キー

```ruby
# アプリ側のマイグレーション
add_foreign_key :shops, :basho_cities, column: :city_code, primary_key: :code
add_foreign_key :shops, :basho_prefectures, column: :prefecture_code, primary_key: :code
```

### DBモデルの直接利用

ActiveRecordの機能（JOIN、スコープ、eager loading）が必要な場合は、DBモデルを直接使います:

```ruby
# JOIN
Basho::DB::City.joins(:prefecture).where(basho_prefectures: { region_name: "関東" })

# Eager loading
Basho::DB::Prefecture.includes(:cities).find(13)

# アソシエーション
prefecture = Basho::DB::Prefecture.find(13)
prefecture.cities    # => ActiveRecord::Relation
prefecture.capital   # => Basho::DB::City
```

### 再シード

`basho:seed`は冪等です。gem更新後に再実行すればデータが更新されます:

```bash
rails basho:seed
```

### 補足

- 郵便番号はDBテーブルに**含まれません**（12万件以上、月次更新のため）。常にJSONファイルから提供されます。
- `Basho.db?`はスレッドセーフでキャッシュされます。再検出が必要な場合（テスト中のマイグレーション後など）は`Basho.reset_db_cache!`を使ってください。

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
