use v5.36;
use lib 'lib';
use Article;

say "--- Before: Hard-coded Notifications ---";

my $article = Article->new(
    title          => 'Observer Pattern Explained',
    enable_slack   => 1,
    enable_discord => 1,
    enable_email   => 1,
    enable_line    => 1,
);

$article->publish;
