---
title: "Argon2 調査レポート"
slug: "argon2"
date: 2025-12-19
tags:
  - cryptography
  - password-hashing
description: "Argon2 の設計、バリアント、パラメータ、実装例、運用上の推奨をまとめた技術レポート。"
image: /favicon.png
draft: true
---

## 概要

Argon2 はパスワードハッシュ関数（パスワードベース KDF）で、2015 年の Password Hashing Competition (PHC) の勝者の一つとして採用された設計です。メモリ耐性（memory-hardness）を主要な防御手段として設計され、GPU/ASIC による並列攻撃に対してコストを増やすことを目的としています。

本レポートは Argon2 の基本概念、バリアント、主要パラメータ、セキュリティ上の注意点、実装例（Python/Go/Rust）、運用での推奨方針、移行ガイダンスを簡潔にまとめます。

## 歴史と標準化

- 2015: Password Hashing Competition（PHC）で Argon2 が高評価を受ける。
- RFC 9106: Argon2 の運用上のガイダンスと仕様が整理された文書（Argon2 に関する標準化情報）。
- 参考実装や多数の言語バインディングがコミュニティで提供されている（参照: 公式参照実装、libsodium など）。

## バリアント

- Argon2d: メモリ依存アクセスを行い、GPU/ASIC に対するコスト効果が高い一方で、サイドチャネル攻撃（タイミング/キャッシュ由来）には弱い可能性がある。主に暗号通貨等、パスワード以外の用途向け。
- Argon2i: 読み取りアクセスが独立したパターンで行われ、サイドチャネル耐性が高い（挿入時の低並列での保護）。パスワードハッシュに適するが、GPU によるクラッキング耐性は Argon2d より低い。
- Argon2id: Argon2i と Argon2d のハイブリッド。最初に Argon2i 型のパスを使い、その後 Argon2d 型のパスを使用する。一般的なパスワードハッシュ用途では `Argon2id` が推奨される。

## 設計目標と概念

- メモリハードネス: 計算に大量のメモリを必要とすることで、並列化（GPU/ASIC）による効率的なコスト低減を防ぐ。
- パラメータでコスト制御: メモリ量、反復回数（タイムコスト）、並列度で性能とコストを調整可能。
- ソルト: 各パスワードにランダムなソルトを必須で付与する。

### 主なパラメータ

- `memory`（メモリコスト）: 使用するメモリ量（通常は KiB 単位）。
- `time`（タイムコスト / 回数）: 並列に実行する反復回数（ループ数）。
- `parallelism`（並列度）: スレッド/レーン数（CPUコアに合わせて設定）。
- `salt`（ソルト）: ランダムなバイト列（推奨 16 バイト以上）。
- `hash_len`（出力長）: 生成するハッシュ長（用途により可変、一般的に 16-32+ バイト）。

パラメータは性能とセキュリティをトレードオフするため、運用環境でベンチマークして `0.5〜1.0 秒` 程度の処理時間を目安に設定するのが実務上の常套手段です（サービスの負荷やレイテンシ要件による）。

## セキュリティ特性

- GPU/ASIC に対する抵抗: メモリを大量に使わせることで、ASIC の回路設計上の利点を薄める。とはいえ専用ハードや十分な資源があれば攻撃は可能であり、パラメータを適切に引き上げる必要がある。
- サイドチャネル: Argon2i はサイドチャネル耐性を重視している。Argon2d は高速だがサイドチャネルに弱い可能性がある。Argon2id が一般用途でのバランスを取る。
- レインボー攻撃 / ソルト: ソルトを正しく使用すれば事前計算攻撃（レインボー）は防げる。

## 実装上の注意

- ソルトは必ず一意でランダムに生成する（推奨 16 バイト以上）。
- ハッシュの検証時は定数時間比較を行う。
- ハッシュパラメータ（memory/time/parallelism）はハッシュ文字列に含める形式を採る実装が多く、将来パラメータを変えても既存ハッシュは検証可能にする。
- 秘匿性を高める `pepper` を別管理（アプリ側の安全な設定）で用いることも可能だが、管理リスクを増やす。

## 運用での推奨方針（目安）

- ベースライン方針: 対象サーバの代表的なハードウェア上で、認証にかけられる許容時間（推奨 0.5〜1 秒）を基準に `memory` と `time` を調整する。
- サンプルパラメータ（要ベンチ、参考値）:
  - 低リソース（モバイル/組み込み）: memory=32 MiB, time=2, parallelism=1
  - 標準的なウェブログイン（インタラクティブ）: memory=64–256 MiB, time=2–4, parallelism=2–8
  - 高セキュリティ（バッチ再計算許容）: memory=512–1024 MiB, time=3–5, parallelism=8+

注: 上記はあくまで目安。必ず実環境でベンチ（同時接続数を考慮）してパラメータを決めてください。

## 実装例

### Python（argon2-cffi の例）

```python
from argon2 import PasswordHasher

# デフォルトでも Argon2id を使う実装が多い
ph = PasswordHasher(time_cost=3, memory_cost=65536, parallelism=4)

hash = ph.hash('correct horse battery staple')
try:
    ph.verify(hash, 'correct horse battery staple')
except Exception:
    # 認証失敗
    pass
```

### Go（golang.org/x/crypto/argon2）

```go
import (
    "crypto/rand"
    "encoding/base64"
    "golang.org/x/crypto/argon2"
)

salt := make([]byte, 16)
rand.Read(salt)
hash := argon2.IDKey([]byte(password), salt, 3, 64*1024, 4, 32)
encoded := base64.RawStdEncoding.EncodeToString(hash)
```

### Rust（argon2 crate）

```rust
use argon2::{Argon2, PasswordHasher, password_hash::SaltString};
use rand_core::OsRng;

let salt = SaltString::generate(&mut OsRng);
let argon2 = Argon2::default();
let password_hash = argon2.hash_password(password.as_bytes(), &salt)?;
let hash_string = password_hash.to_string();
```

## 移行ガイダンス（bcrypt 等からの移行）

- 逐次移行: ユーザがログインしたタイミングで既存ハッシュを検証し、新たに Argon2 で再ハッシュして保存する方式が安全で施工しやすい。
- 強制再発行: すべてのユーザに対してパスワードリセットを要求する方法は確実だが UX に影響する。

## ベンチマークとチューニング

- 実行時間、メモリ使用量、並列性のバランスをとるため、代表的なサーバ上でベンチを行う。負荷状況（同時ログイン、バッチ処理）に応じてパラメータを決定する。
- 監視: 認証に関するレイテンシやエラー率を監視し、パラメータ変更時は段階的にロールアウトする。

## 参考（キーワード）

- Password Hashing Competition (PHC)
- RFC 9106 (Argon2 の運用ガイド)
- argon2 参照実装, libsodium
- argon2-cffi (Python), golang.org/x/crypto/argon2 (Go), argon2 crate (Rust)

## まとめと次の提案

- 一般的なパスワード保存用途では `Argon2id` を第一選択とし、運用環境でベンチして `0.5〜1 秒` の範囲でパラメータを決めるのが実務上の良い出発点です。
- 次の作業候補: (1) 本番に近いハードウェアでの具体的なベンチ実行、(2) 既存ユーザハッシュの移行戦略の詳細設計、(3) 実装レビュー（ライブラリ選定・依存管理）。

---
作成: 調査エージェント — 2025-12-19
