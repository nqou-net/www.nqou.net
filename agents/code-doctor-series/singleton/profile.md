# Patient Profile
- Name: 鋭敏なシニアエンジニア (38)
- Role: 大規模Webサービスの基盤チームリーダー
- Personality: 観察眼が鋭く、細部まで見逃さない。論理的で慎重。最初は怪しい診療所（元ネイルサロン）の雰囲気に警戒しているが、ドクターと助手の関係性や振る舞いを冷静に分析している。
- First Person: 「私」
- Context: 最近、システム全体で設定値の不整合が頻発し、原因究明に疲弊している。単一の真実（Single Source of Truth）を求めている。

# Medical Chart
- Symptom: アプリケーション内のあちこちで設定ファイル（Config）を読み込み、それぞれが好き勝手にインスタンス化している。結果、ある場所では古い設定、別の場所では新しい設定が使われ、システムが分裂症気味。
- Metaphor: 「複数の指揮官（Commander）が異なる命令を現場に出している状態（指揮系統の混乱）」
- Cure: Singleton Patternによる「唯一絶対の指揮官」の擁立。
- Technical Note: Perl v5.36の機能（state変数など）を用いたモダンな実装を目指す。
