use v5.36;
use Test::More;
use lib 'lib';
use MockDB;
use DataExporter::CSV;
use DataExporter::JSON;
use DataExporter::XML;

my $db = MockDB->new(data => {
    users => [
        { id => '1', name => 'Alice',   email => 'alice@example.com' },
        { id => '2', name => 'Bob',     email => 'bob@example.com' },
        { id => '3', name => 'Charlie', email => 'charlie@example.com' },
    ],
});

subtest 'CSV export via Template Method' => sub {
    my $exporter = DataExporter::CSV->new(db => $db);
    my $csv = $exporter->export('users');
    like($csv, qr/email,id,name/, 'CSV has sorted headers');
    like($csv, qr/"alice\@example\.com","1","Alice"/, 'CSV contains Alice row');
    like($csv, qr/"bob\@example\.com","2","Bob"/, 'CSV contains Bob row');
    my @lines = split /\n/, $csv;
    is(scalar @lines, 4, 'CSV has header + 3 data rows');
};

subtest 'JSON export via Template Method' => sub {
    my $exporter = DataExporter::JSON->new(db => $db);
    my $json = $exporter->export('users');
    like($json, qr/^\[/, 'JSON starts with [');
    like($json, qr/"name": "Alice"/, 'JSON contains Alice');
    like($json, qr/"email": "bob\@example\.com"/, 'JSON contains Bob email');
};

subtest 'XML export via Template Method' => sub {
    my $exporter = DataExporter::XML->new(db => $db);
    my $xml = $exporter->export('users');
    like($xml, qr/<\?xml version="1\.0"/, 'XML has declaration (hook method)');
    like($xml, qr/<records>/, 'XML has root element');
    like($xml, qr/<name>Alice<\/name>/, 'XML contains Alice');
    like($xml, qr/<email>charlie\@example\.com<\/email>/, 'XML contains Charlie email');
    like($xml, qr/<\/records>/, 'XML has closing root (footer hook)');
};

subtest 'Template Method ensures consistent flow' => sub {
    # All exporters share the same validation logic
    my $db_with_undef = MockDB->new(data => {
        items => [
            { id => '1', name => undef, value => 'test' },
        ],
    });

    my $csv_exp = DataExporter::CSV->new(db => $db_with_undef);
    my $csv = $csv_exp->export('items');
    like($csv, qr/"1","","test"/, 'CSV: undef handled by shared validation');

    my $json_exp = DataExporter::JSON->new(db => $db_with_undef);
    my $json = $json_exp->export('items');
    like($json, qr/"name": ""/, 'JSON: undef handled by shared validation');
};

subtest 'empty table dies (shared behavior)' => sub {
    my $empty_db = MockDB->new(data => { empty => [] });
    for my $class (qw(DataExporter::CSV DataExporter::JSON DataExporter::XML)) {
        my $exp = $class->new(db => $empty_db);
        eval { $exp->export('empty') };
        like($@, qr/No data found/, "$class dies on empty table");
    }
};

subtest 'base class _format() is abstract' => sub {
    my $base = DataExporter->new(db => $db);
    eval { $base->export('users') };
    like($@, qr/must implement _format/, 'Base class dies with abstract method error');
};

done_testing;
