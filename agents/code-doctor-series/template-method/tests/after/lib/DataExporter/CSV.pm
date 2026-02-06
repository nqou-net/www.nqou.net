package DataExporter::CSV;
use v5.36;
use parent 'DataExporter';

sub _format ($self, $rows) {
    my @headers = sort keys $rows->[0]->%*;
    my $output = join(",", @headers) . "\n";

    for my $row ($rows->@*) {
        my @values = map {
            my $v = $row->{$_};
            $v =~ s/"/""/g;
            qq{"$v"};
        } @headers;
        $output .= join(",", @values) . "\n";
    }

    return $output;
}

1;
