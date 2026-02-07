use v5.36;
use lib 'lib';
use Article;
use Notification::Slack;
use Notification::Discord;

say "--- After: Observer Pattern ---";

my $article = Article->new(title => 'Observer Pattern Explained');

# 必要な通知先だけを「プラグイン」のように追加
$article->add_observer(Notification::Slack->new);
$article->add_observer(Notification::Discord->new);

# 将来的に「LINE通知」を足したければ...
# $article->add_observer(Notification::Line->new);
# と書くだけ。Articleクラスの修正は不要（Open/Closed Principle）。

$article->publish;
