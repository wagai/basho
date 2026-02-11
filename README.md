[日本語版はこちら](README.ja.md)

# Basho

A Ruby gem for working with Japanese address data -- prefectures, cities, postal codes, and regions -- in a unified interface.

## Why Basho

Dealing with Japanese addresses is tedious.

- Looking up an address from a postal code requires parsing CSVs and loading them into a database
- Maintaining master data for prefectures and cities means writing migrations
- Postal code auto-fill and prefecture-city cascading selects end up being rewritten every project
- Existing gems are tightly coupled to Rails, have outdated data, or lack Hotwire support

Basho solves all of these.

## Features

- **No DB migrations** -- All data is bundled as JSON. Just `gem install` and go
- **Optional DB backend** -- Generate tables for JOINs and foreign keys. The API auto-switches transparently
- **Framework-agnostic** -- Works with plain Ruby, Sinatra, Rails API-only, or any Ruby app
- **ActiveRecord integration** -- `include Basho` + a one-line macro for automatic postal code to address resolution on save
- **Hotwire-ready** -- Built-in Rails Engine with postal code auto-fill via Turbo Frame + Stimulus
- **Lightweight** -- Immutable models via `Data.define`, lazy loading, zero external dependencies

## Supported Versions

- Ruby 3.2 / 3.3 / 3.4 / 4.0

## Installation

```ruby
# Gemfile
gem "basho"
```

```bash
bundle install
```

## Quick Start

### Look up an address from a postal code

```ruby
postal = Basho::PostalCode.find("154-0011")
postal.prefecture_name  # => "東京都"
postal.city_name        # => "世田谷区"
postal.town             # => "上馬"
```

### Auto-save address columns from a postal code

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

### Search prefectures and cities

```ruby
Basho::Prefecture.find(13).name           # => "東京都"
Basho::Prefecture.where(region: "関東")    # => 7 prefectures
Basho::City.find("131016").name            # => "千代田区"
```

## Usage

### Prefecture

```ruby
# Class methods
Basho::Prefecture.find(13)                 # Find by code (Integer)
Basho::Prefecture.find(name: "東京都")      # Find by Japanese name
Basho::Prefecture.find(name_en: "Tokyo")   # Find by English name
Basho::Prefecture.all                      # All 47 prefectures
Basho::Prefecture.where(region: "関東")     # Filter by region name
```

```ruby
# Instance methods / members
pref = Basho::Prefecture.find(13)
pref.code          # => 13            (Integer)
pref.name          # => "東京都"       (String)
pref.name_en       # => "Tokyo"       (String)
pref.name_kana     # => "トウキョウト"  (String, katakana)
pref.name_hiragana # => "とうきょうと"  (String, hiragana)
pref.region_name   # => "関東"         (String)
pref.type          # => "都"           (String: "都" / "道" / "府" / "県")
pref.capital_code  # => "131016"       (String, 6-digit city code)
pref.region        # => Basho::Region
pref.cities        # => Array<Basho::City>
pref.capital       # => Basho::City (prefectural capital)
```

### City

```ruby
# Class methods
Basho::City.find("131016")              # Find by 6-digit municipality code (String)
Basho::City.where(prefecture_code: 13)  # Filter by prefecture code (Integer)
Basho::City.valid_code?("131016")       # Validate JIS X 0401 check digit
```

```ruby
# Instance methods / members
city = Basho::City.find("131016")
city.code             # => "131016"    (String, 6-digit)
city.prefecture_code  # => 13          (Integer)
city.name             # => "千代田区"   (String)
city.name_kana        # => "チヨダク"   (String, katakana)
city.district         # => nil         (String or nil, e.g. "島尻郡")
city.capital          # => false       (Boolean, raw member)
city.capital?         # => false       (Boolean, prefectural capital?)
city.full_name        # => "千代田区"   (String, prepends district if present)
city.prefecture       # => Basho::Prefecture
```

`district` is set only for towns/villages that belong to a county (gun). For example:

```ruby
city = Basho::City.find("473821")
city.name       # => "八重瀬町"
city.district   # => "島尻郡"
city.full_name  # => "島尻郡八重瀬町"
```

### PostalCode

`find` returns a single `PostalCode` or `nil`. `where` returns an `Array` (may contain multiple results for shared postal codes).

```ruby
# Class methods
Basho::PostalCode.find("154-0011")    # => PostalCode or nil (first match)
Basho::PostalCode.find("1540011")     # Hyphenless format also works
Basho::PostalCode.where(code: "154-0011")  # => Array<PostalCode>
```

```ruby
# Instance methods / members
postal = Basho::PostalCode.find("154-0011")
postal.code              # => "1540011"   (String, 7 digits, no hyphen)
postal.formatted_code    # => "154-0011"  (String, with hyphen)
postal.prefecture_code   # => 13          (Integer)
postal.city_name         # => "世田谷区"   (String)
postal.town              # => "上馬"       (String)
postal.prefecture_name   # => "東京都"     (String)
postal.prefecture        # => Basho::Prefecture
```

### Region

9 regions: Hokkaido, Tohoku, Kanto, Chubu, Kinki, Chugoku, Shikoku, Kyushu, Okinawa.

```ruby
# Class methods
Basho::Region.all                # => Array of 9 regions
Basho::Region.find("関東")       # Find by Japanese name
Basho::Region.find("Kanto")     # Find by English name
```

```ruby
# Instance methods / members
region = Basho::Region.find("関東")
region.name             # => "関東"     (String)
region.name_en          # => "Kanto"   (String)
region.prefecture_codes # => [8, 9, 10, 11, 12, 13, 14]  (Array<Integer>)
region.prefectures      # => Array<Basho::Prefecture>
```

## ActiveRecord Integration

Add `include Basho` to your model to enable the `basho` and `basho_postal` macros.

### Look up prefecture and city from a municipality code

```ruby
class Shop < ApplicationRecord
  include Basho
  basho :local_gov_code
end

shop.city         # => Basho::City
shop.prefecture   # => Basho::Prefecture
shop.full_address # => "東京都千代田区"
```

`basho :column` defines three instance methods:

| Method | Return value |
|--------|-------------|
| `city` | `Basho::City` found by the column value |
| `prefecture` | `Basho::Prefecture` via `city.prefecture` |
| `full_address` | `"#{prefecture.name}#{city.name}"` or `nil` |

### Get an address string from a postal code

```ruby
class Shop < ApplicationRecord
  include Basho
  basho_postal :postal_code
end

shop.postal_address # => "東京都世田谷区上馬"
```

`basho_postal :column` (without mapping options) defines a `postal_address` method that returns `"#{prefecture_name}#{city_name}#{town}"` or `nil`.

### Auto-save address columns from a postal code

When you pass mapping options to `basho_postal`, it registers a `before_save` callback that auto-fills address columns whenever the postal code column changes.

```ruby
class User < ApplicationRecord
  include Basho
  basho_postal :postal_code,
    prefecture: :pref_name,
    city: :city_name,
    town: :town_name
end
```

Available mapping keys:

| Key | Resolved value |
|-----|---------------|
| `prefecture:` | Prefecture name (e.g. "東京都") |
| `city:` | City name (e.g. "世田谷区") |
| `town:` | Town name (e.g. "上馬") |
| `prefecture_code:` | Prefecture code (e.g. 13) |
| `city_code:` | 6-digit municipality code (e.g. "131130") |

- Resolution runs only when the postal code column will change on save
- Partial mappings are supported (e.g. `prefecture:` only)
- The `postal_address` method is always defined regardless of mapping options

## Hotwire Engine

A built-in Rails Engine providing postal code auto-fill via Turbo Frame + Stimulus.

### Setup

Mount the Engine in your routes:

```ruby
# config/routes.rb
mount Basho::Engine, at: "/basho"
```

The Engine provides a single route:

| Method | Path | Controller#Action |
|--------|------|------------------|
| GET | `/basho/postal_codes/lookup?code=1540011` | `Basho::PostalCodesController#lookup` |

The Stimulus controller and form helper are automatically registered via importmap and `ActionView` initializers.

### Postal Code Auto-fill

Automatically fills in prefecture, city, and town fields when a 7-digit postal code is entered.

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

How it works:

1. User enters a 7-digit postal code
2. A Turbo Frame request is sent to the Engine's lookup endpoint
3. Stimulus fills the prefecture, city, and town fields and shows the `fields` container
4. When the postal code is cleared or incomplete, the fields are hidden

The `fields` target is optional. Without it, the fields remain visible and are simply cleared.

You can use the `basho_autofill_frame_tag` helper instead of writing the `<turbo-frame>` tag manually:

```erb
<%= basho_autofill_frame_tag %>
```

This renders:

```html
<turbo-frame id="basho-result"
             data-basho--auto-fill-target="frame"
             data-action="turbo:frame-load->basho--auto-fill#fill"></turbo-frame>
```

#### Stimulus Controller Targets and Values

| Type | Name | Description |
|------|------|-------------|
| Value | `url` (String) | Lookup endpoint URL (required) |
| Target | `input` | Postal code input field |
| Target | `frame` | Turbo Frame for server response |
| Target | `prefecture` | Prefecture output field |
| Target | `city` | City output field |
| Target | `town` | Town output field |
| Target | `fields` | Container to show/hide (optional) |

### Prefecture-City Cascade Select

Basho provides the data -- build the UI in your app using Turbo Frame.

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
        { include_blank: "Select city" } %>
</turbo-frame>
```

```erb
<%# In your form %>
<%= f.select :prefecture_code,
      Basho::Prefecture.all.map { |p| [p.name, p.code] },
      { include_blank: "Select prefecture" },
      data: { action: "change->auto-submit#submit",
              turbo_frame: "city-select" } %>

<turbo-frame id="city-select">
  <%= f.select :city_code, [], include_blank: "Select city" %>
</turbo-frame>
```

This keeps the HTML and styling in your app where it belongs.

## Without Hotwire

The data API and ActiveRecord integration work without Hotwire. If you don't mount the Engine, no routes or Stimulus controllers are loaded.

```ruby
# Just the data API -- works in any Ruby app
require "basho"

Basho::PostalCode.find("154-0011").town         # => "上馬"
Basho::Prefecture.find(13).name                 # => "東京都"
Basho::City.where(prefecture_code: 13)          # => Array<City>
```

```ruby
# ActiveRecord integration -- works in any Rails app, Hotwire or not
class Shop < ApplicationRecord
  include Basho
  basho_postal :postal_code, city_code: :city_code, town: :town
end
```

## DB Backend (Optional)

By default, Basho loads all data from bundled JSON files -- no database needed. If you need JOINs, foreign key constraints, or want to reference `basho_prefectures` / `basho_cities` from your own tables, you can optionally generate DB tables.

### Setup

```bash
rails generate basho:install_tables
rails db:migrate
rails basho:seed
```

This creates two tables:

| Table | Primary Key | Rows |
|-------|------------|------|
| `basho_prefectures` | `code` (integer) | 47 |
| `basho_cities` | `code` (string, 6-digit) | ~1,900 |

### Transparent Auto-switching

Once the tables exist, the public API (`Basho::Prefecture.find`, `Basho::City.where`, etc.) automatically uses the DB backend. **No code changes required.**

```ruby
# Works exactly the same whether DB tables exist or not
Basho::Prefecture.find(13).name           # => "東京都"
Basho::City.find("131016").full_name      # => "千代田区"
Basho::City.where(prefecture_code: 13)    # => Array
```

Detection happens once on first access via `Basho.db?` and is cached for the process lifetime.

### Foreign Keys from Your Tables

```ruby
# Your app migration
add_foreign_key :shops, :basho_cities, column: :city_code, primary_key: :code
add_foreign_key :shops, :basho_prefectures, column: :prefecture_code, primary_key: :code
```

### Direct DB Model Access

When you need ActiveRecord features (JOINs, scopes, eager loading), use the DB models directly:

```ruby
# JOINs
Basho::DB::City.joins(:prefecture).where(basho_prefectures: { region_name: "関東" })

# Eager loading
Basho::DB::Prefecture.includes(:cities).find(13)

# Associations
prefecture = Basho::DB::Prefecture.find(13)
prefecture.cities    # => ActiveRecord::Relation
prefecture.capital   # => Basho::DB::City
```

### Re-seeding

`basho:seed` is idempotent. Run it again after updating the gem to refresh the data:

```bash
rails basho:seed
```

### Notes

- Postal codes are **not** included in the DB tables (120k+ rows, updated monthly). They are always served from bundled JSON files.
- `Basho.db?` is thread-safe and cached. Use `Basho.reset_db_cache!` if you need to re-detect (e.g. after running migrations in a test).

## Data Sources

| Data | Source | Update Frequency |
|------|--------|-----------------|
| Prefectures | Ministry of Internal Affairs, JIS X 0401 | Rarely changes |
| Cities | Ministry of Internal Affairs, Local Government Codes | A few times per year |
| Postal codes | Japan Post KEN_ALL.csv | Monthly (auto-updated via GitHub Actions) |
| Regions | 9 regions (hardcoded) | Never changes |

## Development

```bash
git clone https://github.com/wagai/basho.git
cd basho
bin/setup
bundle exec rspec
```

## License

MIT License
