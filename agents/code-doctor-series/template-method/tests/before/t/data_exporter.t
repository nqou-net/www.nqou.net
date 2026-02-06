use v5.36;
use Test::More;
use lib 'lib';
use MockDB;
use DataExporter;

my $db = MockDB->new(data => {
    users => [
        { id => '1', name => 'Alice',   email => 'alice@example.com' },
        { id => '2', name => 'Bob',     email => 'bob@example.com' },
        { id => '3', name => 'Charlie', email => 'charlie@example.com' },
    ],
});

my $exporter = DataExporter->new(db => $db);

subtest 'CSV export' => sub {
    my $csv = $exporter->export_csv('users');
    like($csv, qr/email,id,name/, 'CSV has sorted headers');
    like($csv, qr/"alice\@example\.com","1","Alice"/, 'CSV contains Alice row');
    like($csv, qr/"bob\@example\.com","2","Bob"/, 'CSV contains Bob row');
    my @lines = split /\n/, $csv;
    is(scalar @lines, 4, 'CSV has header + 3 data rows');
};

subtest 'JSON export' => sub {
    my $json = $exporter->export_json('users');
    like($json, qr/^\[/, 'JSON starts with [');
    like($json, qr/"name": "Alice"/, 'JSON contains Alice');
    like($json, qr/"email": "bob\@example\.com"/, 'JSON contains Bob email');
};

subtest 'XML export' => sub {
    my $xml = $exporter->export_xml('users');
    like($xml, qr/<\?xml version="1\.0"/, 'XML has declaration');
    like($xml, qr/<records>/, 'XML has root element');
    like($xml, qr/<name>Alice<\/name>/, 'XML contains Alice');
    like($xml, qr/<email>charlie\@example\.com<\/email>/, 'XML contains Charlie email');
};

subtest 'empty table dies' => sub {
    my $empty_db = MockDB->new(data => { empty => [] });
    my $exp = DataExporter->new(db => $empty_db);
    eval { $exp->export_csv('empty') };
    like($@, qr/No data found/, 'Dies on empty table');
};

subtest 'undef values handled' => sub {
    my $db_with_undef = MockDB->new(data => {
        items => [
            { id => '1', name => undef, value => 'test' },
        ],
    });
    my $exp = DataExporter->new(db => $db_with_undef);
    my $csv = $exp->export_csv('items');
    like($csv, qr/"1","","test"/, 'undef converted to empty string in CSV');
};

done_testing;
