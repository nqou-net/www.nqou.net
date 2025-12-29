---
title: "Test2 調査ログ"
draft: false
tags:
- "test2"
description: "Perl の Test2 テストフレームワークに関する調査メモ"
---

## 概要

Test2 は Perl のモダンなテストフレームワーク群（Test2 スイート）の総称で、従来の Test::More / Test::Builder の設計を再構築し、モジュール性・拡張性・詳細な診断・並列実行などを提供します。

中心的な利用方法は `Test2::V0` を使ったテスト記述（バッテリ同梱のツールセット）です。

## 主なコンポーネント（抜粋）

- `Test2::V0` — 日常のテストを書くための便利なラッパー（`ok`, `is`, `like`, `subtest`, `dies` などを提供）
- `Test2::Suite` — Test2 のツール群を集めたスイート
- `Test2::API`, `Test2::Event`, `Test2::Hub` など — ツール・プラグイン・ハブの基盤
- `Test2::Mock`, `Test2::Tools::*`, `Test2::Formatter::TAP` などのエコシステム

## インストール

推奨（開発環境）:

```
---
title: "Test2 調査ログ"
draft: false
tags:
	- "test2"
description: "Perl の Test2 テストフレームワークに関する調査メモ"
---

## 概要

Test2 は Perl のモダンなテストフレームワーク群（Test2 スイート）の総称で、従来の Test::More / Test::Builder の設計を再構築し、モジュール性・拡張性・詳細な診断・並列実行などを提供します。

中心的な利用方法は `Test2::V0` を使ったテスト記述（バンドルされたツール群）です。

## 主なコンポーネント（抜粋）

- `Test2::V0` — 日常のテストを書くための便利なラッパー（`ok`, `is`, `like`, `subtest`, `dies` などを提供）
- `Test2::Suite` — Test2 のツール群を集めたスイート
- `Test2::API`, `Test2::Event`, `Test2::Hub` など — ツール・プラグイン・ハブの基盤
- `Test2::Mock`, `Test2::Tools::*`, `Test2::Formatter::TAP` などのエコシステム

## インストール

推奨（開発環境）:

```sh
cpanm Test2::Suite
# または個別に
cpanm Test2::V0
```

CI では `prove -lvr t/` など従来の `prove` コマンドで実行できます。

## 基本的な使い方（例）

```perl
use Test2::V0;
ok(1, 'this passes');
is(1+1, 2, 'math works');
like('hello world', qr/world/, 'pattern matches');
subtest 'group' => sub { is($x, $y, 'equal'); };
done_testing;
```

例外・警告のテスト例:

```perl
like( dies { dangerous() }, qr/Error/, 'dies with message');
like( warns { deprecated() }, qr/deprecate/, 'warns as expected');
```

構造比較や `bag` / `hash` 等を使った複雑データの検証も強力にサポートされます。

## リポジトリ内の発見（nqou-net/www.nqou.net）

生成済みの `docs/` に Test2 関連の記事・サンプルが複数ありました。代表例:

- `docs/tags/test2/index.html`
- `docs/tags/test2-v0/index.html`
- 記事: "Test2フレームワーク入門"
- 記事: "MooによるTDD講座 #1 / #2"（Test2 を用いた TDD チュートリアル、サンプルコードあり）

注: `docs/` は生成物のため、実ソースは `content/` 下にあるはずです（今回の簡易検索で `docs/` がヒットしました）。

## 参考リンク

- Test2（MetaCPAN）：https://metacpan.org/release/Test2
- Test2::V0（MetaCPAN）：https://metacpan.org/pod/Test2::V0
- Test2 GitHub：https://github.com/Test-More/Test2

## 調査結果（Investigation Results）

### 調査課題

- Test2 の主要コンポーネントと役割を整理する（`Test2::V0`, `Test2::API`, `Test2::Hub` 等）
- 既存の Test::More ベースのテストからの移行コストと互換性を評価する
- CI（prove 等）での実行方法、並列実行のサポート、カバレッジツールとの併用方法を確認する
- 実運用でのベストプラクティス（モック、サブテスト、診断出力の取り扱い）を収集する

### 成功基準

- 主要ドキュメント（MetaCPAN、GitHub）の参照を基に各コンポーネントの用途を説明できる
- 既存テストを `Test2::V0` に移行する際の具体的手順と注意点が示せる
- CI 環境で `prove` などを使い並列実行や `Devel::Cover` と組み合わせる手順が示せる
- 代表的な実装例（GitHub 等）を 2〜3 件以上見つけ、パターンを要約できる

### 次のアクション

1. 公式ドキュメント（MetaCPAN）の主要 POD を精査する（`Test2::V0`, `Test2::Suite`, `Test2::Event` など）。
2. GitHub 上で `Test2::V0` を使っているリポジトリを検索し、実装パターンを収集する。
3. 必要なら最小プロトタイプ（ローカル Perl + `cpanm`）で `prove -lvr t/` を実行して挙動を確認する（実行は要許可）。
4. 本ログに逐次追記し、最終的に `結論と推奨` を確定する。

### 所見（短いまとめ）

- インストール: `cpanm Test2::Suite` または個別に `cpanm Test2::V0`。
- 実行: 既存の `prove -lvr t/` が使えるケースが多い。並列実行が必要な場合は `Test2::Harness` 系の利用を検討。
- バンドル/ツール: `Test2::Suite` は多くの `Tools` と `Plugins` を提供。`Test2::Bundle::More` は互換性を意識しているが完全一致ではない。
- 比較動作: `Test2::Tools::Compare` の深い比較は強力だが、従来挙動と差が出る場合があるため注意が必要。
- モック: `Test2::Mock` は強力でテスト内での差し替え/追跡が容易。
- 移行上の注意点: `tests => N` 指定やプランニングの扱いが従来と異なるケースがあるため、`done_testing` を推奨する場面がある。

### CI 実行メモ（短い手順）

1. 依存インストール: `cpanm --installdeps .` または `cpanm Test2::Suite`
2. テスト実行（シンプル）: `prove -lvr t/`
3. 並列・ハーネス: 並列化が必要なら `Test2::Harness::UI` やハーネス経由の実行を検討
4. カバレッジ: `Devel::Cover` と組み合わせる（CI のコマンド調整が必要）

## モジュール別所見（要点）

- **Test2::V0**: 日常的なテスト記述のためのバンドル。`use Test2::V0` と `done_testing` の組合せが使いやすい。
- **Test2::Suite / Bundles**: 用途別のバンドルあり。`Bundle::More` は互換性を意識しているが差分あり。
- **Test2::Tools::Compare**: 深い比較に優れるが、出力や失敗時の差異に注意。
- **Test2::Mock**: モック/差し替えに便利。テスト終了時の自動復元設計。
- **Test2::Harness**: 並列実行や詳細なハーネス制御に有用。

## 結論と推奨

- 短期（今すぐ）:
	- CI のテストコマンドは当面 `prove -lvr t/` を継続し、必要な Test2 モジュールを `test` 依存に追加する（`cpanfile` の `test_requires`）。
	- `Test2::V0` を新規テストで採用し、既存の `Test::More` ベーステストは段階的に移行する（ファイル単位で移行テストを行う）。

- 中期（検討）:
	- 並列実行や大規模並列テストが必要であれば、`Test2::Harness` 系に移行してベンチを取る。
	- `Devel::Cover` 等カバレッジ測定と組み合わせる際は `PERL5OPT` の調整や環境変数を CI に追加する。

- 長期（改善）:
	- テストパターン（`Test2::Mock` の使い方、`Tools::Compare` の活用パターン）を社内テンプレート化し、新規プロジェクトでの採用ガイドを作成する。

## 更新履歴

- 2025-12-16: 調査・要約を作成（GitHub Copilot）

---

調査日時: 2025-12-16
調査者: GitHub Copilot (automation)

## 参考（外部事例）

MetaCPAN や公開リポジトリで `Test2::V0` を `test` 依存に使っている例が多数あります。必要なら実例 URL を列挙します。

