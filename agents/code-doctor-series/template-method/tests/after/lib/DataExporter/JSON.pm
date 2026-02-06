package DataExporter::JSON;
use v5.36;
use parent 'DataExporter';

sub _format ($self, $rows) {
    my @json_rows;

    for my $row ($rows->@*) {
        my @pairs;
        for my $key (sort keys $row->%*) {
            my $v = $row->{$key};
            $v =~ s/\\/\\\\/g;
            $v =~ s/"/\\"/g;
            push @pairs, qq{    "$key": "$v"};
        }
        push @json_rows, "  {\n" . join(",\n", @pairs) . "\n  }";
    }

    return "[\n" . join(",\n", @json_rows) . "\n]\n";
}

1;
