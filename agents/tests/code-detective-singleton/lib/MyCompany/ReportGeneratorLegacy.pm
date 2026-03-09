package MyCompany::ReportGeneratorLegacy;
use strict;
use warnings;
use MyCompany::Database; # Singletonクラスに依存

sub new { bless {}, shift }

sub generate {
    my ($self, $user_id) = @_;
    
    # 💥 問題箇所の発火点：暗黙の依存関係（グローバルステートへのアクセス）
    # generatorの利用者は、内部で本番DBのSingletonが呼ばれていることに気づけない
    my $db = MyCompany::Database->get_instance();
    my $data = $db->fetch_user_data($user_id);
    
    return "Report for $data->{name}";
}

1;
