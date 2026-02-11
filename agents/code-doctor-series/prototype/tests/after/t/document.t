use v5.36;
use Test::More;

require './lib/DocumentTemplate/Prototype.pm';

subtest 'レジストリからのテンプレート生成' => sub {
    my $registry = DocumentTemplate::Registry->build_default;
    my @types    = $registry->list_types;
    ok scalar @types >= 4, 'テンプレート種別が4つ以上登録されている';
};

subtest '議事録テンプレートの clone' => sub {
    my $registry = DocumentTemplate::Registry->build_default;
    my $doc      = $registry->create(
        '議事録',
        department => '営業部',
        author     => '田中',
        date       => '2025-06-15',
    );
    is $doc->type,                '議事録',            '種別が正しい';
    is $doc->department,          '営業部',            '部署がオーバーライドされた';
    is $doc->metadata->{company}, '株式会社テックソリューション', 'メタデータは原型を継承';
    is scalar $doc->sections->@*, 4,                'セクション数が正しい';
};

subtest '日報テンプレートの clone' => sub {
    my $registry = DocumentTemplate::Registry->build_default;
    my $doc      = $registry->create(
        '日報',
        author => '鈴木',
        date   => '2025-06-16',
    );
    is $doc->type,   '日報', '種別が正しい';
    is $doc->author, '鈴木', '作成者がオーバーライドされた';
};

subtest '障害報告書の clone' => sub {
    my $registry = DocumentTemplate::Registry->build_default;
    my $doc      = $registry->create(
        '障害報告書',
        department => 'インフラ部',
        author     => '佐藤',
        date       => '2025-06-17',
    );
    is $doc->type,                '障害報告書', '種別が正しい';
    is scalar $doc->sections->@*, 5,       '障害報告書は5セクション';
};

subtest 'メタデータのオーバーライド' => sub {
    my $registry = DocumentTemplate::Registry->build_default;
    my $doc      = $registry->create('議事録', metadata => {division => '経理部'},);
    is $doc->metadata->{division}, '経理部',            'メタデータの部署がオーバーライドされた';
    is $doc->metadata->{company},  '株式会社テックソリューション', '他のメタデータは保持';
};

subtest 'deep clone の検証 — shallow copy の罠なし' => sub {
    my $registry = DocumentTemplate::Registry->build_default;
    my $doc1     = $registry->create(
        '議事録',
        department => '開発部',
        author     => '三橋',
    );
    my $doc2 = $registry->create(
        '議事録',
        department => '経理部',
        author     => '山田',
        metadata   => {division => '経理部'},
    );

    # 2つの clone は完全に独立している
    is $doc1->department,           '開発部', 'doc1の部署は元のまま';
    is $doc2->department,           '経理部', 'doc2の部署は変更済み';
    is $doc1->metadata->{division}, '開発部', 'doc1のメタデータは独立';
    is $doc2->metadata->{division}, '経理部', 'doc2のメタデータも独立';

    # sections も独立していることを確認
    $doc2->sections->[0]{content} = '変更テスト';
    is $doc1->sections->[0]{content}, '', 'doc1のセクションは影響を受けない';
};

subtest '未登録テンプレートのエラー' => sub {
    my $registry = DocumentTemplate::Registry->build_default;
    eval { $registry->create('存在しないテンプレート') };
    like $@, qr/未登録のテンプレート/, '未登録テンプレートでエラー';
};

done_testing;
