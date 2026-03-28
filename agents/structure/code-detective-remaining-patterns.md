# コード探偵ロック 連載計画 v2

最終更新: 2026-03-29

旧4/6-4/17の12パターンを新28パターンと統合し、7アーク全40話で再構成。

---

## Arc 1: コードの悪臭捜査編（4/6〜4/12）全7話

リファクタリング系アンチパターン。実務で頻出するコードの臭いを探偵が嗅ぎ分ける。

| # | 日付 | テーマ | slug | 特殊回 | タスク |
|---|------|--------|------|--------|--------|
| 1 | 4/6 | Feature Envy | feature-envy | — | tasks/20260406.md |
| 2 | 4/7 | Law of Demeter（Train Wreck） | law-of-demeter | ★関連: Feature Envy(4/6) | tasks/20260407.md |
| 3 | 4/8 | Middle Man | middle-man | ★対極: Law of Demeter(4/7) | tasks/20260408.md |
| 4 | 4/9 | Refused Bequest | refused-bequest | — | tasks/20260409.md |
| 5 | 4/10 | Dead Code / Lava Flow | dead-code-lava-flow | — | tasks/20260410.md |
| 6 | 4/11 | Magic Numbers / Strings | magic-numbers | — | tasks/20260411.md |
| 7 | 4/12 | Temporal Coupling | temporal-coupling | ★発展: Builder(3/21) | tasks/20260412.md |

## Arc 2: 依存の迷宮編（4/13〜4/18）全6話

依存性管理と拡張性。Service Locator → DI → Registry の三つ巴から、条件とプラグインの世界へ。

| # | 日付 | テーマ | slug | 特殊回 | タスク |
|---|------|--------|------|--------|--------|
| 8 | 4/13 | Service Locator | service-locator | — | tasks/20260413.md |
| 9 | 4/14 | Dependency Injection | dependency-injection | ★対比: Service Locator(4/13) | tasks/20260414.md |
| 10 | 4/15 | Registry Pattern | registry-pattern | ★三つ巴: SL(4/13)+DI(4/14) | tasks/20260415.md |
| 11 | 4/16 | Specification | specification-pattern | — | tasks/20260416.md |
| 12 | 4/17 | Type Object Pattern | type-object-pattern | — | tasks/20260417.md |
| 13 | 4/18 | Plugin / Extension Pattern | plugin-pattern | ★関連: Specification(4/16) | tasks/20260418.md |

## Arc 3: ドメインの深淵編（4/19〜4/25）全7話

DDD（ドメイン駆動設計）パターン。Interpreter でドメイン言語の扉を開き、不変性の Money で締める。

| # | 日付 | テーマ | slug | 特殊回 | タスク |
|---|------|--------|------|--------|--------|
| 14 | 4/19 | Interpreter | interpreter-pattern | — | tasks/20260419.md |
| 15 | 4/20 | Aggregate（集約） | aggregate | — | tasks/20260420.md |
| 16 | 4/21 | Domain Event | domain-event | ★発展: Observer(3/7) | tasks/20260421.md |
| 17 | 4/22 | Bounded Context | bounded-context | ★続編: Aggregate(4/20) | tasks/20260422.md |
| 18 | 4/23 | Entity vs Value Object | entity-vs-value-object | ★続編: Value Object(3/10) | tasks/20260423.md |
| 19 | 4/24 | Immutable Object | immutable-object | ★発展: Entity vs VO(4/23) | tasks/20260424.md |
| 20 | 4/25 | Money Pattern | money-pattern | ★総括: Immutable Object(4/24) | tasks/20260425.md |

## Arc 4: 処理の連鎖編（4/26〜4/30）全5話

データフローと分散処理。単純なパイプラインから、分散トランザクション、メッセージングへ進化する。

| # | 日付 | テーマ | slug | 特殊回 | タスク |
|---|------|--------|------|--------|--------|
| 21 | 4/26 | Pipeline | pipeline-pattern | — | tasks/20260426.md |
| 22 | 4/27 | Double Dispatch | double-dispatch | ★関連: Visitor(3/31) | tasks/20260427.md |
| 23 | 4/28 | Saga | saga-pattern | ★発展: Pipeline(4/26) | tasks/20260428.md |
| 24 | 4/29 | Outbox Pattern | outbox-pattern | ★続編: Event Sourcing(4/3)+Saga(4/28) | tasks/20260429.md |
| 25 | 4/30 | Publish-Subscribe | publish-subscribe | ★総括: Observer(3/7)+Domain Event(4/21) | tasks/20260430.md |

## Arc 5: 不死身のシステム I — 防衛線編（5/1〜5/5）全5話

耐障害性パターン。障害の検知→リトライ→タイムアウト→フォールバック→流量制御と、防衛の段階を踏む。

| # | 日付 | テーマ | slug | 特殊回 | タスク |
|---|------|--------|------|--------|--------|
| 26 | 5/1 | Circuit Breaker | circuit-breaker | — | tasks/20260501.md |
| 27 | 5/2 | Retry Pattern | retry-pattern | ★続編: Circuit Breaker(5/1) | tasks/20260502.md |
| 28 | 5/3 | Timeout Pattern | timeout-pattern | — | tasks/20260503.md |
| 29 | 5/4 | Fallback Pattern | fallback-pattern | ★続編: Retry(5/2)+Timeout(5/3) | tasks/20260504.md |
| 30 | 5/5 | Rate Limiting / Throttling | rate-limiting | — | tasks/20260505.md |

## Arc 6: 不死身のシステム II — 資源管理編（5/6〜5/9）全4話

リソース管理と監視。隔壁→プール→遅延→健康診断と、システムの内臓を守る。

| # | 日付 | テーマ | slug | 特殊回 | タスク |
|---|------|--------|------|--------|--------|
| 31 | 5/6 | Bulkhead | bulkhead-pattern | ★関連: Rate Limiting(5/5) | tasks/20260506.md |
| 32 | 5/7 | Object Pool | object-pool | ★関連: Bulkhead(5/6) | tasks/20260507.md |
| 33 | 5/8 | Lazy Loading | lazy-loading | — | tasks/20260508.md |
| 34 | 5/9 | Health Check Pattern | health-check-pattern | ★総括: 耐障害性アーク全体 | tasks/20260509.md |

## Arc 7: 外壁の向こう側編（5/10〜5/15）全6話

メッセージングとアーキテクチャ移行。外部世界との境界を守り、レガシーを超える最終章。

| # | 日付 | テーマ | slug | 特殊回 | タスク |
|---|------|--------|------|--------|--------|
| 35 | 5/10 | Dead Letter Queue | dead-letter-queue | — | tasks/20260510.md |
| 36 | 5/11 | Competing Consumers | competing-consumers | — | tasks/20260511.md |
| 37 | 5/12 | Anti-Corruption Layer | anti-corruption-layer | — | tasks/20260512.md |
| 38 | 5/13 | Strangler Fig Pattern | strangler-fig | ★発展: ACL(5/12) | tasks/20260513.md |
| 39 | 5/14 | API Gateway | api-gateway | ★関連: ACL(5/12) | tasks/20260514.md |
| 40 | 5/15 | Backends for Frontends (BFF) | backends-for-frontends | ★最終回: API Gateway(5/14) | tasks/20260515.md |

---

## 特殊回の系譜マップ

```
Feature Envy(4/6) ←関連→ Law of Demeter(4/7) ←対極→ Middle Man(4/8)
Builder(3/21) ──→ Temporal Coupling(4/12)

Service Locator(4/13) ←対比→ DI(4/14) ←三つ巴→ Registry(4/15)
Specification(4/16) ──→ Plugin(4/18)

Observer(3/7) ──→ Domain Event(4/21) ──→ Publish-Subscribe(4/30)
Value Object(3/10) ──→ Entity vs VO(4/23) ──→ Immutable(4/24) ──→ Money(4/25)
Aggregate(4/20) ──→ Bounded Context(4/22)
Visitor(3/31) ──→ Double Dispatch(4/27)

Pipeline(4/26) ──→ Saga(4/28) ──→ Outbox(4/29)
Event Sourcing(4/3) ──→ Outbox(4/29)

Circuit Breaker(5/1) ──→ Retry(5/2) ──→ Fallback(5/4)
                                          ↑
                          Timeout(5/3) ───┘
Rate Limiting(5/5) ──→ Bulkhead(5/6) ──→ Object Pool(5/7)
全耐障害性パターン ──→ Health Check(5/9)

ACL(5/12) ──→ Strangler Fig(5/13)
ACL(5/12) ──→ API Gateway(5/14) ──→ BFF(5/15)
```

---

## 使い方

series-author スキルにタスクファイルのパスを渡して記事を生成する。

```
tasks/20260406.md のパスを series-author スキルに渡してください
```

## 合計

**全40話（特殊回21話 / 通常回19話）**
**期間: 2026年4月6日〜5月15日**
**7アーク構成**
