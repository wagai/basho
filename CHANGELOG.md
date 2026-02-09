# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.2] - 2026-02-09

### Fixed

- Railsアプリで`Basho::Engine`が自動読み込みされない問題を修正

## [0.2.1] - 2026-02-09

### Fixed

- `PostalAutoResolve.resolve_city_code`で郡のある町村（923件）の`city_code`が解決されないバグを修正

## [0.2.0] - 2026-02-08

### Added

- `City#district` - 郡名（例: `"島尻郡"`）。郡に属する町村のみ設定
- `City#full_name` - 郡名付き正式名を返す（例: `"島尻郡八重瀬町"`）
- `tasks/import/districts.rb` - PostalCodeデータから郡名を抽出するスクリプト

### Fixed

- KEN_ALL.CSVとの異体字不整合を修正（`梼原町` → `檮原町`、`須恵町` → `須惠町`）

## [0.1.2] - 2026-02-08

### Changed

- 沖縄県を九州地方から分離し「沖縄」地方として独立（8地方区分 → 9地方区分）

## [0.1.0] - 2026-02-08

### Added

- `Basho::Prefecture` - 47都道府県の検索（コード・日本語名・英語名）、地方での絞り込み
- `Basho::City` - 市区町村の検索（6桁JISコード）、都道府県コードでの絞り込み
- `Basho::PostalCode` - 郵便番号の検索（ハイフン有無対応、1対多マッピング）
- `Basho::Region` - 8地方区分の検索（日本語/英語名）
- `Basho::CodeValidator` - JIS X 0401 チェックディジット検証
- `Basho::Data::Loader` - JSONデータの遅延読み込みとキャッシュ
- `Basho::ActiveRecord::Base` - `basho` / `basho_postal` マクロ
- 都道府県・市区町村・郵便番号のJSONデータ同梱
- GitHub Actions CI（Ruby 3.2/3.3/3.4）
- 月次データ自動更新ワークフロー

[0.2.2]: https://github.com/wagai/basho/releases/tag/v0.2.2
[0.2.1]: https://github.com/wagai/basho/releases/tag/v0.2.1
[0.2.0]: https://github.com/wagai/basho/releases/tag/v0.2.0
[0.1.2]: https://github.com/wagai/basho/releases/tag/v0.1.2
[0.1.0]: https://github.com/wagai/basho/releases/tag/v0.1.0
