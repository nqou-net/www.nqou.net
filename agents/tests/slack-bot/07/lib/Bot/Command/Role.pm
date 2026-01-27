package Bot::Command::Role;
use Moo::Role;
use Types::Standard qw(Str);

requires 'match';       # 引数解釈（戻り値: 引数ハッシュリファレンス or undef）
requires 'execute';     # 処理実行（戻り値: 結果文字列）
requires 'description'; # ヘルプ用説明

1;
