# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.0] - 2026-02-11

### Added

- オプションDBバックエンド（`basho_prefectures` / `basho_cities` テーブル）
- `rails generate basho:install_tables` マイグレーションジェネレータ
- `rails basho:seed` Rakeタスク（冪等、JSON→DB一括投入）
- `Basho::DB::Prefecture` / `Basho::DB::City` ActiveRecordモデル
- `Basho.db?` によるDB自動検出（スレッドセーフ、キャッシュ付き）
- テーブルが存在すれば公開API（`Prefecture.find`, `City.where`等）が自動でDB経由に切り替わる
- READMEにDB Backendセクション追加（EN/JA）

## [0.3.0] - 2026-02-11

### Changed

- **BREAKING**: `PostalCode.find()` が配列ではなく単一の `PostalCode` または `nil` を返すように変更
- **BREAKING**: `PostalCode.where()` がキーワード引数 `where(code:)` に変更
- **BREAKING**: カスケードセレクト機能を削除（Stimulusコントローラー、都道府県/市区町村JSON API、フォームヘルパー）
- **BREAKING**: 郵便番号JSONのキー名 `city` → `city_name`、都道府県JSONのキー名 `region` → `region_name` に統一
- `auto_fill_controller.js` をTurboイベント駆動にシンプル化（デバウンス削除）
- `PostalAutoResolve` をシンプルなcase文ベースに簡素化
- 市区町村データソースを `jp_local_gov` gem から KEN_ALL.CSV に変更（外部gem依存を撤廃）
- `districts.rb` のロジックを `cities.rb` に統合

### Added

- `PostalCode.where(code:)` - 配列で結果を返す検索メソッド
- Engine initializerでフォームヘルパーを自動インクルード
- `Data::Loader` にパストラバーサル防御を追加

### Fixed

- KEN_ALL.CSVインポートの複数行町域名結合バグを修正（208件）
- 「の次に番地がくる場合」の町域名が空にならないバグを修正（17件）
- 名古屋市・大阪市・広島市の不正なdistrictデータを修正
- 市区町村カナを正規化（旧式カタカナ → 正式カタカナ、15件）

### Removed

- `Basho::PrefecturesController` （都道府県/市区町村JSON API）
- `basho_cascade_data` フォームヘルパーメソッド
- `cascade_select_controller.js` Stimulusコントローラー
- `/basho/prefectures` ルート
- `tasks/import/districts.rb`（`cities.rb` に統合）
- `jp_local_gov` gem への依存

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

[0.4.0]: https://github.com/wagai/basho/releases/tag/v0.4.0
[0.3.0]: https://github.com/wagai/basho/releases/tag/v0.3.0
[0.2.2]: https://github.com/wagai/basho/releases/tag/v0.2.2
[0.2.1]: https://github.com/wagai/basho/releases/tag/v0.2.1
[0.2.0]: https://github.com/wagai/basho/releases/tag/v0.2.0
[0.1.2]: https://github.com/wagai/basho/releases/tag/v0.1.2
[0.1.0]: https://github.com/wagai/basho/releases/tag/v0.1.0
