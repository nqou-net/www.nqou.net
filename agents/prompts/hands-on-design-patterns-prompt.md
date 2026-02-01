# 手で覚えるデザインパターンシリーズ プロンプトテンプレート

> 対象ワークフロー: `/planning-v2` → `/series-unified-*`

---

## 使用方法

```
@[/planning-v2]

「Perlで学ぶ手で覚えるデザインパターンシリーズ」の構造案を作成してください。

## 入力パラメータ

### 使用するデザインパターン
| 順序 | パターン名 | 役割（任意） |
|------|-----------|-------------|
| 1    | <パターン名> | <このパターンが担う役割> |
| 2    | <パターン名> | <このパターンが担う役割> |
| 3    | <パターン名> | <このパターンが担う役割> |

### シリーズ設定
- 出力形式: 統合版 / 連載版
- 全体回数: 6-10回目安
- 公開予定日: YYYY-MM-DD

### テーマの希望（オプション）
- 方向性: <ゲーム系/ツール系/セキュリティ系/日常生活系など>
- 避けたいテーマ: <既存シリーズと重複を避けるため>
- 想定読者の興味: <ウイスキー/ゲーム/ネットワークなど>
```

---

## 生成される内容

1. **3つの案（A/B/C）** - それぞれ異なるテーマ・題材で
2. **各案の連載構造表** - 全回分のタイトル・概念・ストーリー
3. **USP（独自の価値提案）** - なぜこのシリーズを読む価値があるか
4. **推薦案と理由**

---

## 制約事項（自動適用）

- 1記事1概念の原則を守る
- 「動く→破綻→パターン導入→完成」のストーリー展開
- パターン名は記事タイトルに入れず、最終回で明かす
- コード例は各回2つまで（破綻版 + 改善版）

---

## パターン選択ガイド

### GoFパターン一覧

**生成系（Creational）**
- Abstract Factory, Builder, Factory Method, Prototype, Singleton

**構造系（Structural）**
- Adapter, Bridge, Composite, Decorator, Facade, Flyweight, Proxy

**振る舞い系（Behavioral）**
- Chain of Responsibility, Command, Interpreter, Iterator, Mediator, Memento, Observer, State, Strategy, Template Method, Visitor

### おすすめ組み合わせ例

| パターン組み合わせ | 相性の良いテーマ例 |
|------------------|-------------------|
| Factory Method + Strategy + Template Method | ゲームAI、レポート生成 |
| Composite + Visitor + Iterator | ファイルシステム、DOM操作 |
| Observer + Decorator + Command | チャット、ログシステム |
| State + Memento + Command | ゲーム状態管理、エディタ |
| Flyweight + Prototype + Abstract Factory | グラフィック、オブジェクト生成 |
| Bridge + Adapter + Proxy | API統合、リモートアクセス |

---

## 入力例

### 例1: 最小限

```
@[/planning-v2]

Factory Method + Strategy + Observer のパターンで「手で覚えるシリーズ」の構造案を作って
形式: 統合版
```

### 例2: テーマ指定あり

```
@[/planning-v2]

「Perlで学ぶ手で覚えるデザインパターンシリーズ」の構造案を作成してください。

## 入力パラメータ

### 使用するデザインパターン
| 順序 | パターン名 | 役割 |
|------|-----------|------|
| 1    | Composite | ツリー構造の表現 |
| 2    | Visitor | ツリー走査時の処理 |
| 3    | Iterator | 要素の巡回 |

### シリーズ設定
- 出力形式: 統合版
- 全体回数: 8回程度
- 公開予定日: 2026-02-15

### テーマの希望
- 方向性: ファイルシステム管理ツール
- 避けたいテーマ: ゲーム系（既存と重複）
```

---

## 次のステップ

構造案が生成されたら:

1. `/series-unified-prepare` — 準備（案選定、日時決定）
2. `/series-unified-code` — コード実装
3. `/series-unified-write` — 原稿作成
4. `/series-unified-visual` — 挿絵生成（オプション）
5. `/series-unified-review` — 最終レビュー

---

**作成日**: 2026-02-01
**参照**: `agents/structure/hands-on-design-patterns-series-structure.md`
