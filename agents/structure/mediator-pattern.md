---
title: 連載構造案 - 仲介者でさばく事件簿シリーズ（全5回）
description: Mediatorパターンを題材に、遊び心ある題材で疎結合と調停の妙を体感する連載構造案A/B/C
draft: true
tags:
  - design-pattern
  - mediator
  - series-planning
image: /favicon.png
references:
  - content/warehouse/mediator-pattern.md
---

# 連載構造案：Mediatorパターンを学ぶ新シリーズ

調査結果: `content/warehouse/mediator-pattern.md` を参照

## 前提情報

- 技術スタック: Perl v5.36+（signatures, postfix deref）, Moo
- 想定読者: Perl入学式卒業、Moo OOP入門修了者
- 学習ゴール: SRP/OCP を壊してから仲介者で救う体験、双方向依存の解消、イベント調停の設計センス獲得
- 制約: シリーズ名にパターン名を入れない／1記事1概念／各回コード例2つまで／完成コードは原則1ファイル（分割時は構造明示）
- ストーリー型: 動く→破綻→Mediator導入→完成コード

---

## 案A: 「地下ハッカソン運営ダッシュボード」

- USP: ハッカソン会場の混線した通知・設備連携を仲介者で捌く。「現場っぽいリアルなカオス」を整理する快感。  
- 有料価値: 実用寄りのドメインで、イベント運営自動化をそのまま自宅案件に転用できる。
- 特徴: 王道のイベント調停題材。Slack風通知・電源管理・入退室ログを仲介で束ねる。
- メリット: ドメインが身近／双方向依存の整理が明快。デメリット: 非GUIで地味に見えがち。

### 連載構造表
| 回数 | タイトル | 新概念(1記事1) | ストーリー | コード例1/2 | 推奨タグ |
|---|---|---|---|---|---|
| 1 | 配線だらけの現場をスクリプトで可視化 | 単純イベント配送 | 入退室ログ→通知を直配線で実装 | CLIログ配信 / 簡易Notifier | design-pattern,perl,moo |
| 2 | アラート増殖で泥沼化 | SRP/OCP違反の顕在化 | 電源/Slack/表示板が相互依存で爆発 | 依存関係図出力 / テストダミー | design-pattern,perl,anti-pattern |
| 3 | 調停役を立てる | Mediatorインターフェース | 仲介者がイベント配線を一手に受ける | mediatorロール / subscribe路線 | mediator,perl,architecture |
| 4 | 役割別Mediatorで分割統治 | 複数Mediator | 設備系と通知系でMediator分割 | multi-mediator / dispatch table | mediator,perl,modularity |
| 5 | 完成版: ハッカソン運営ダッシュボード | 完成コード | 1ファイル(or lib/)で仕上げ | 完成CLI / テストシナリオ | perl,moo,cli |

- 差別化ポイント: 実務っぽい混線を仲介者で整理し、複数Mediator分割まで踏み込む。
- 推薦案: **A推し**。読者がそのままイベント自動化に使える再現性が高く、SRP/OCPの痛みが実感しやすい。

---

## 案B: 「闇市オークション・シミュレータ」

- USP: 怪しげな即売イベントで「出品者/買い手/闇オークショニア」の利害調整を仲介者で制御。  
- 有料価値: 同時入札・フェイク入札・手数料計算など複雑な取引ロジックを仲介で制御する設計が学べる。
- 特徴: 競合する入札イベントを一元調停。ランダム性とゲーム性をミックス。
- メリット: ゲーム性で飽きにくい。デメリット: 倫理的トーンに配慮しつつ表現調整が必要。

### 連載構造表
| 回数 | タイトル | 新概念(1記事1) | ストーリー | コード例1/2 | 推奨タグ |
|---|---|---|---|---|---|
| 1 | まずは闇市を開場する | イベントブローカー基礎 | 出品/入札を直結で実装 | bidder→seller直呼び / ログ表示 | perl,moo,auction |
| 2 | 荒らし入札でシステム崩壊 | SRP/OCP違反 | フェイク入札で依存が爆発 | God object化 / 例外多発 | anti-pattern,perl |
| 3 | 仲介者を雇う | Mediator基本 | AuctionMediatorで入札ルール集中 | mediator dispatch / fee calc | mediator,perl,oop |
| 4 | ルール差し替え可能に | 戦略差替え＋Mediator | 夜市/昼市で手数料と制裁を切替 | strategy-like rule set / config | mediator,extensibility |
| 5 | 完成版: 闇市オークション・シム | 完成コード | 1ファイル完成＋動作例 | demo run / seed固定 | perl,simulation |

- 差別化ポイント: 入札ルールの差し替え・制裁ロジックを仲介者に集約し、可変シナリオを楽しめる。
- 推薦案: **B推し**。可変ルール×ゲーム性で学習体験が印象に残る。

---

## 案C: 「IoT温室の指令塔」

- USP: 温度/湿度/照度/送風をバラバラのセンサーとアクチュエータが殴り合う温室を、仲介者で静かに統制。  
- 有料価値: 実世界IoT風の調停を単一ファイルで再現し、後からセンサー追加しても壊れない設計を示す。
- 特徴: センサーイベントと制御命令を双方向で仲介。アラート連携も追加。
- メリット: 現実感と再現性。デメリット: ドメイン用語が多くやや重め。

### 連載構造表
| 回数 | タイトル | 新概念(1記事1) | ストーリー | コード例1/2 | 推奨タグ |
|---|---|---|---|---|---|
| 1 | 温室をスクリプトで動かす | 単純制御ループ | 温度→送風を直結で制御 | loop制御 / printログ | perl,iot |
| 2 | センサー追加で制御崩壊 | SRP/OCP違反 | 湿度/照度追加で条件分岐沼 | nested if地獄 / coupling | anti-pattern,perl |
| 3 | 司令塔(Mediator)を挟む | Mediator基本 | SensorHubが制御命令を調停 | mediator hub / routing | mediator,perl,iot |
| 4 | プロファイル切替と優先度 | ルール優先度 | 昼夜・季節プロファイルを仲介者で切替 | priority table / profile | mediator,config |
| 5 | 完成版: 温室指令塔 | 完成コード | 1ファイル(or lib/)完成 | demo run / profile切替 | perl,automation |

- 差別化ポイント: IoT風リアルドメインで優先度制御を仲介者に集約し、後付けセンサーを安全に追加できる。
- 推薦案: **C補完**。実務×ハード寄りシナリオで堅実に学びたい読者向け。

---

## レビュー履歴

- 2026-01-20: 初版作成（案A/B/C提示、self-review）

