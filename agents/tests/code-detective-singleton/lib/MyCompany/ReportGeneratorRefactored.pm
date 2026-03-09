package MyCompany::ReportGeneratorRefactored;
use Moo;

# 💡 解決策：Dependency Injection (DI)
# 依存するオブジェクト（DBコネクション等）は、自ら見つけに行くのではなく
# 外部から「注入（要求）」する設計にする。
has db => (
    is       => 'ro',
    required => 1, # 必ず外部から渡すことを強制する
    # isa => 'Object', # 厳密にはRole(Interface)等の型を指定する
);

sub generate {
    my ($self, $user_id) = @_;
    
    # コンストラクタで渡されたDBオブジェクトを利用する
    # このメソッドは、DBが本物かモックかを全く気にしなくて良くなる（関心の分離）
    my $data = $self->db->fetch_user_data($user_id);
    
    return "Report for $data->{name}";
}

1;
