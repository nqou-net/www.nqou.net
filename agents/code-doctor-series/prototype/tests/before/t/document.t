use v5.36;
use Test::More;

# テスト対象を直接ロード
require './lib/DocumentTemplate.pm';

subtest '議事録テンプレートの生成' => sub {
    my $doc = DocumentTemplate::Minutes->new_template(
        department => '営業部',
        author     => '田中',
        date       => '2025-06-15',
    );
    is $doc->{type}, '議事録', '種別が正しい';
    is $doc->{department}, '営業部', '部署が正しい';
    is $doc->{metadata}{company}, '株式会社テックソリューション', '会社名が正しい';
    is scalar $doc->{sections}->@*, 4, 'セクション数が正しい';
};

subtest '日報テンプレートの生成' => sub {
    my $doc = DocumentTemplate::DailyReport->new_template(
        department => '開発部',
        author     => '鈴木',
        date       => '2025-06-16',
    );
    is $doc->{type}, '日報', '種別が正しい';
    is $doc->{metadata}{division}, '開発部', 'メタデータの部署が正しい';
};

subtest '障害報告書テンプレートの生成' => sub {
    my $doc = DocumentTemplate::IncidentReport->new_template(
        department => 'インフラ部',
        author     => '佐藤',
        date       => '2025-06-17',
    );
    is $doc->{type}, '障害報告書', '種別が正しい';
    is scalar $doc->{sections}->@*, 5, '障害報告書は5セクション';
};

# === ここでバグが露呈する ===
subtest 'shallow copy の罠' => sub {
    my $doc1 = DocumentTemplate::Minutes->new_template(
        department => '開発部',
        author     => '三橋',
    );
    # 「コピー」のつもりでハッシュの浅いコピーを作る
    my $doc2 = { $doc1->%* };

    # doc2 のメタデータだけ変えたつもり
    $doc2->{metadata}{division} = '経理部';
    $doc2->{type} = '経理議事録';

    # doc2 を変えたはずなのに……
    is $doc2->{type}, '経理議事録', 'doc2の種別は変わった';
    is $doc2->{metadata}{division}, '経理部', 'doc2のメタデータも変わった';

    # ここが問題！ doc1 のメタデータも壊れている！
    # 本来は '開発部' であるべき
    TODO: {
        local $TODO = '既知のバグ: shallow copy で参照が共有される';
        is $doc1->{metadata}{division}, '開発部',
            'doc1のメタデータは元のまま……のはず';
    }
};

done_testing;
