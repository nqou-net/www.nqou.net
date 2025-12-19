# Perl と Mojolicious の最新情報（2025-12-19）

## 概要
短くまとめると:
- Perl 本体は引き続きメンテされており、最新版のダウンロードが公式で案内されている（ページ上に `5.42.0` ダウンロードへのリンクが確認できる）
- CPAN は活発で多数のモジュールが継続的に公開されている（ページ上の統計は約 225,000 モジュール）
- Mojolicious は活発なフレームワークで、公式サイト・ドキュメント・MetaCPAN が整備されている。動作要件として Perl 5.26.0 以上を推奨している旨がドキュメントに記載されている

---

## 要点
- Perl: 公式サイトで最新版（5.42.0 への案内）を確認。The Perl Foundation や Perl/CPAN のニュース（寄付、Dancer2 2.0.0 など）あり
- CPAN: モジュール数・ディストリビューション数は増加中。最近のアップロード一覧が常時更新されている
- Mojolicious: フレームワークの公式ガイドが充実。非同期/WebSocket/HTTP クライアント/サーバ機能が強力で、軽量プロトタイプから本番アプリまで対応

---

## Perl 本体（公式サイト確認）
- 公式: https://www.perl.org/ にてダウンロード案内とニュースを確認
- 目立つ点:
  - トップページに `5.42.0 DOWNLOAD` へのリンクが表示されている（執筆時点の公式案内）
  - The Perl Foundation の寄付・コミュニティ活動のニュースが継続して公開されている（例: DuckDuckGo 等からの寄付記事）

推奨アクション:
- システムに導入している Perl バージョンが古い場合、テスト環境で `5.42.0` への移行を検討する（CPAN モジュール互換性を事前検証）

---

## CPAN（エコシステム）
- CPAN のトップ（https://www.cpan.org/）ではモジュール総数や最近のアップロードが確認できる
- Metacpan が検索/ドキュメントの標準的な参照先になっている（https://metacpan.org/）
- モジュール/ディストリビューションの頻繁な更新が続いており、セキュリティフィックスや新機能追加が日常的に行われている

推奨アクション:
- 主要依存モジュールについては `cpan-outdated` や CI の依存更新チェックを導入して継続的に監視する
- セキュリティ関連のアップデートは優先的にテスト→展開する

---

## Mojolicious（フレームワーク）
- 公式サイト: https://mojolicious.org/（ドキュメントへの導線が充実）
- MetaCPAN: https://metacpan.org/release/Mojolicious
- GitHub: https://github.com/mojolicious/mojo （リポジトリ、Issue、PR が参照可能）

主なポイント:
- Mojolicious はリアルタイム Web（WebSocket、非同期処理）、組み込みHTTP/HTTPSクライアント/サーバ機能、テンプレート、テストフレームワーク等を備えるフルスタックな軽量フレームワーク
- ドキュメント上では Perl 5.26.0 以上が要件として明示されている（互換性に関する注記あり）
- GitHub の "Releases" ページに明確なリリースノートが無い場合があるが、MetaCPAN のリリース履歴やコミットログ、CHANGELOG を参照すると最新の変更を追える

推奨アクション:
- Mojolicious を使うプロジェクトはまずドキュメント（https://docs.mojolicious.org/）を参照して最小必要 Perl バージョンを満たすこと
- 本番移行前に `morbo`/`hypnotoad` 等の推奨ランタイムでの負荷テストを実施する
- Mojolicious プラグイン（例: Minion 等）の互換性とメンテナンス状況を確認する

---

## セキュリティ・運用上の注意点
- Perl/CPAN の多さゆえに依存ツリーが複雑になりやすい。自動更新のCIパイプラインと署名/検証の運用を検討する
- Mojolicious は非同期処理や WebSocket を扱うため、接続のタイムアウトやリソース制限（コネクション数など）を明確に設定する

---

## 参考リンク（収集元）
- Perl 公式: https://www.perl.org/
- CPAN: https://www.cpan.org/
- MetaCPAN - Mojolicious: https://metacpan.org/release/Mojolicious
- Mojolicious 公式: https://mojolicious.org/
- Mojolicious GitHub: https://github.com/mojolicious/mojo
- ドキュメント: https://docs.mojolicious.org/

---

## 次のステップ（提案）
- 依存しているプロジェクトがあれば、現行の Perl バージョンと主要 CPAN モジュールのバージョンを列挙して互換性チェックを行う
- Mojolicious を使用する実アプリがあるなら、テスト環境で `5.42.0` と最新 Mojolicious の組合せによる回帰テストを実施する


(記録日時: 2025-12-19)
