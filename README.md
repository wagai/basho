[日本語版はこちら](README.ja.md)

# Basho

A Ruby gem for working with Japanese address data — prefectures, cities, postal codes, and regions — in a unified interface.

## Why Basho

Dealing with Japanese addresses is tedious.

- Looking up an address from a postal code requires parsing CSVs and loading them into a database
- Maintaining master data for prefectures and cities means writing migrations
- Postal code auto-fill and prefecture-city cascading selects end up being rewritten every project
- Existing gems are tightly coupled to Rails, have outdated data, or lack Hotwire support

Basho solves all of these.

- **No DB migrations** — All data is bundled as JSON. Just `gem install` and go
- **Framework-agnostic** — Works with plain Ruby, Sinatra, Rails API-only, or any Ruby app
- **ActiveRecord integration** — `include Basho` + a one-line macro for automatic postal code to address resolution on save (optional)
- **Hotwire-ready** — Built-in Rails Engine with postal code auto-fill via Turbo Frame + Stimulus (optional)
- **Lightweight** — Immutable models via `Data.define`, lazy loading, zero external dependencies

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
Basho::Prefecture.where(region: "関東")    # => 7 results
Basho::City.find("131016").name            # => "千代田区"
```

## Usage

### Prefecture

```ruby
Basho::Prefecture.find(13)             # Find by code
Basho::Prefecture.find(name: "東京都")  # Find by name
Basho::Prefecture.all                   # All 47 prefectures
Basho::Prefecture.where(region: "関東") # Filter by region

pref = Basho::Prefecture.find(13)
pref.code          # => 13
pref.name          # => "東京都"
pref.name_en       # => "Tokyo"
pref.name_kana     # => "トウキョウト"
pref.name_hiragana # => "とうきょうと"
pref.type          # => "都"
pref.region        # => Region
pref.cities        # => Array<City>
pref.capital       # => City (prefectural capital)
```

### City

```ruby
Basho::City.find("131016")              # Find by municipality code
Basho::City.where(prefecture_code: 13)  # Filter by prefecture
Basho::City.valid_code?("131016")       # Validate check digit

city = Basho::City.find("131016")
city.code             # => "131016"
city.prefecture_code  # => 13
city.name             # => "千代田区"
city.name_kana        # => "チヨダク"
city.capital?         # => false
city.prefecture       # => Prefecture
```

### PostalCode

```ruby
postal = Basho::PostalCode.find("154-0011")   # => PostalCode or nil
postal = Basho::PostalCode.find("1540011")    # Hyphenless format also works
postal.code              # => "1540011"
postal.formatted_code    # => "154-0011"
postal.prefecture_code   # => 13
postal.prefecture_name   # => "東京都"
postal.city_name         # => "世田谷区"
postal.town              # => "上馬"
postal.prefecture        # => Prefecture
```

### Region

```ruby
Basho::Region.all                # 9 regions
Basho::Region.find("関東")       # Find by name

region = Basho::Region.find("関東")
region.name             # => "関東"
region.name_en          # => "Kanto"
region.prefectures      # => Array<Prefecture>
region.prefecture_codes # => [8, 9, 10, 11, 12, 13, 14]
```

## ActiveRecord Integration

### Look up prefecture and city from a municipality code

```ruby
class Shop < ApplicationRecord
  include Basho
  basho :local_gov_code
end

shop.prefecture   # => Prefecture
shop.city         # => City
shop.full_address # => "東京都千代田区"
```

### Get an address string from a postal code

```ruby
class Shop < ApplicationRecord
  include Basho
  basho_postal :postal_code
end

shop.postal_address # => "東京都世田谷区上馬"
```

### Auto-save address columns from a postal code

When you pass mapping options to `basho_postal`, it registers a `before_save` callback that auto-fills address columns from the postal code.

```ruby
class User < ApplicationRecord
  include Basho
  basho_postal :postal_code,
    prefecture: :pref_name,
    city: :city_name,
    town: :town_name
end
```

- Resolution runs only when `postal_code` changes
- Partial mappings are supported (e.g. `prefecture:` only)
- Without options, only the `postal_address` method is defined (backward compatible)

## Hotwire Engine

A built-in Rails Engine providing postal code auto-fill via Turbo Frame + Stimulus.

### Setup

```ruby
# config/routes.rb
mount Basho::Engine, at: "/basho"
```

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

1. User enters a 7-digit postal code
2. A Turbo Frame request is sent to the Engine
3. Stimulus fills the prefecture, city, and town fields and shows them
4. When the postal code is cleared or incomplete, the fields are hidden

The `fields` target is optional. Without it, the fields remain visible and are simply cleared.

You can also use the `basho_autofill_frame_tag` helper instead of writing the `<turbo-frame>` tag manually:

```erb
<%= basho_autofill_frame_tag %>
```

### Prefecture-City Cascade Select

Basho provides the data — build the UI in your app using Turbo Frame.

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
# Just the data API — works in any Ruby app
require "basho"

Basho::PostalCode.find("154-0011").town         # => "上馬"
Basho::Prefecture.find(13).name                 # => "東京都"
Basho::City.where(prefecture_code: 13)          # => Array<City>
```

```ruby
# ActiveRecord integration — works in any Rails app, Hotwire or not
class Shop < ApplicationRecord
  include Basho
  basho_postal :postal_code, city_code: :city_code, town: :town
end
```

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
