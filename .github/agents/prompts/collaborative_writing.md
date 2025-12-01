## 協力型記事作成プロンプトテンプレート

用途: 専門家（perl-specialist、ruby-specialist等）とblog-writerが協力してブログ記事を作成するためのワークフロー。

### ワークフロー概要

1. **専門家が原稿を作成**: 技術的に正確で詳細な原稿
2. **blog-writerが編集**: 読みやすく魅力的なブログ記事に仕上げる

---

## フェーズ1: 専門家による原稿作成

### 使用エージェント
- `perl-specialist` (Perl記事の場合)
- `ruby-specialist` (Ruby記事の場合)
- その他の専門エージェント

### 指示テンプレート

```
{topic} に関する技術記事の原稿を作成してください。

【記事のテーマ】
{topic}

【ターゲット読者】
{audience} (例: Perl初心者、経験豊富な開発者、など)

【記事の目的】
{purpose} (例: 特定の技術を解説する、問題解決方法を示す、など)

【含めるべき内容】
- {content_point_1}
- {content_point_2}
- {content_point_3}

【要求事項】
1. 技術的に正確な情報を提供する
2. 動作確認済みのコード例を含める
3. 必要な専門用語は遠慮なく使用する（後でblog-writerが補足説明を追加します）
4. バージョン情報や依存関係を明記する
5. コミュニティのベストプラクティスに従う

【出力形式】
- Markdown形式
- コードブロックには言語を指定
- Front matterは不要（blog-writerが追加します）
```

### 出力例（専門家の原稿）

```markdown
# Perlでの非同期処理 - Minionの活用

## 概要

Minionはモダンなジョブキューシステムです。
バックグラウンドタスクの処理に最適です。

## インストール

cpanfileに以下を追加：

    requires 'Minion';
    requires 'Minion::Backend::SQLite';

インストール：

    cpanm --installdeps .

## 基本的な使用方法

ワーカーの定義：

```perl
use Minion;

my $minion = Minion->new(SQLite => 'sqlite:minion.db');

$minion->add_task(send_email => sub {
  my ($job, @args) = @_;
  # メール送信処理
  $job->finish('Email sent');
});
```

ジョブのエンキュー：

```perl
my $id = $minion->enqueue(send_email => ['user@example.com']);
```

ワーカーの起動：

```perl
$minion->worker->run;
```

## 依存関係

- Perl 5.16+
- Minion 10.0+
- DBD::SQLite (SQLiteバックエンド使用時)

## 参考資料

- Minion公式ドキュメント: https://metacpan.org/pod/Minion
```

---

## フェーズ2: blog-writerによる編集

### 使用エージェント
- `blog-writer`

### 指示テンプレート

```
以下の技術記事原稿を、読みやすく魅力的なブログ記事に編集してください。

【専門家の原稿】
{specialist_draft}

【編集の方針】
1. 技術的な正確性は維持する（内容は変更しない）
2. 読者を引きつける導入部を追加
3. 専門用語には簡単な補足説明を追加
4. 適切な見出し階層と段落分けを行う
5. まとめセクションを追加
6. Front matterを作成（title, description, tags, draft: true）

【ターゲット読者】
{audience}

【記事のトーン】
{tone} (例: 親しみやすく技術的、フォーマルで専門的、など)

【要求事項】
- ファイル名: `{epoch_time}.md` 形式
- 保存先: `content/post/`
- Front matterの `draft` は必ず `true`
- ショートコード（linkcard, amazon等）を適宜使用
```

### 出力例（編集後のブログ記事）

```markdown
---
title: "Perlで簡単バックグラウンド処理！Minionで非同期タスクを実装する"
description: "モダンなPerlジョブキューMinionを使って、メール送信などの重い処理をバックグラウンドで実行する方法を解説します"
tags: [perl, minion, async, job-queue, backend]
draft: true
date: 2024-01-15
---

Webアプリケーションで、メール送信や画像処理など時間のかかる処理を実行すると、
ユーザーを長時間待たせてしまいますよね。

そんなときに便利なのが **バックグラウンドジョブ** です。
今回は、Perlのモダンなジョブキューシステム「Minion」を使って、
非同期処理を簡単に実装する方法を紹介します。

## Minionとは？

Minionは、Perlのモダンなジョブキューシステムです。
重い処理をバックグラウンドで実行し、Webリクエストのレスポンスを高速に保つことができます。

主な特徴：
- シンプルなAPI
- 複数のバックエンド対応（PostgreSQL、SQLite等）
- ジョブの優先度設定、リトライ機能
- リアルタイムのジョブ監視

## セットアップ

まずは必要なモジュールをインストールしましょう。

`cpanfile` に以下を追加します：

```perl
requires 'Minion';
requires 'Minion::Backend::SQLite';  # 開発環境ではSQLiteが手軽
```

インストールは簡単：

```bash
cpanm --installdeps .
```

## 基本的な使い方

### 1. ワーカータスクの定義

まず、バックグラウンドで実行したいタスクを定義します。
ここでは、メール送信タスクを例にします：

```perl
use Minion;

# Minionインスタンスの作成（SQLiteバックエンド使用）
my $minion = Minion->new(SQLite => 'sqlite:minion.db');

# タスク 'send_email' を登録
$minion->add_task(send_email => sub {
  my ($job, @args) = @_;
  
  # メール送信処理（実際のロジックはここに書く）
  my $email = $args[0];
  # ... メール送信 ...
  
  # ジョブ完了を通知
  $job->finish("Email sent to $email");
});
```

### 2. ジョブのエンキュー（登録）

Webアプリケーションから、ジョブをキューに追加します：

```perl
# メール送信ジョブをキューに追加
my $job_id = $minion->enqueue(send_email => ['user@example.com']);

# すぐにレスポンスを返せる（メール送信を待たない）
say "ジョブ登録完了: $job_id";
```

### 3. ワーカーの起動

別プロセスでワーカーを起動し、ジョブを処理します：

```perl
# ワーカーを起動（キューを監視してジョブを実行）
$minion->worker->run;
```

実際の運用では、systemdやsupervisor等でワーカープロセスを管理すると良いでしょう。

## 動作環境

- **Perl**: 5.16以降
- **Minion**: 10.0以降
- **データベース**: SQLite (開発用) または PostgreSQL (本番推奨)

## まとめ

Minionを使えば、Perlでも簡単にバックグラウンドジョブを実装できます。

この記事で紹介したのは基本的な使い方ですが、Minionには以下のような高度な機能もあります：
- ジョブの優先度設定
- 遅延実行とスケジューリング
- 失敗時の自動リトライ
- Webダッシュボードでのジョブ監視

ぜひ公式ドキュメントもチェックして、より深く活用してみてください！

## 参考資料

{{< linkcard url="https://metacpan.org/pod/Minion" >}}
```

---

## 変数の説明

| 変数 | 説明 | 例 |
|------|------|-----|
| `{topic}` | 記事のテーマ | "Perlでの非同期処理" |
| `{audience}` | ターゲット読者 | "Perl中級者" |
| `{purpose}` | 記事の目的 | "Minionの基本的な使い方を解説" |
| `{content_point_N}` | 含めるべき内容 | "インストール方法"、"基本的なコード例" |
| `{specialist_draft}` | 専門家が書いた原稿 | （上記の出力例参照） |
| `{tone}` | 記事のトーン | "親しみやすく技術的" |
| `{epoch_time}` | エポック秒（ファイル名用） | "1705305600" |

## 注意事項

1. **技術的正確性の維持**: blog-writerは専門家の技術的内容を変更しない
2. **draft設定**: 生成された記事は必ず `draft: true`
3. **ビルド実行禁止**: エージェントはビルドコマンドを実行しない
4. **最終確認**: 記事公開前にユーザーがレビューする
