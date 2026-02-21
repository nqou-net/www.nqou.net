package SaaS::API::Client;
use v5.36;

sub new($class) {
    bless {
        calls => 0, # モック用のカウンタ
    }, $class;
}

# 100件ずつ返すモックAPI
sub get_users($self, $page = 1) {
    $self->{calls}++;
    
    # 全1025件のデータをシミュレート
    my $total_items = 1025;
    my $per_page    = 100;
    my $start_idx   = ($page - 1) * $per_page;
    
    return { items => [], next_page => undef } if $start_idx >= $total_items;
    
    my $end_idx = $start_idx + $per_page - 1;
    $end_idx = $total_items - 1 if $end_idx >= $total_items;
    
    my @items = map { { id => $_ + 1, name => "User " . ($_ + 1) } } ($start_idx .. $end_idx);
    
    my $next_page = ($end_idx < $total_items - 1) ? $page + 1 : undef;
    
    return {
        items     => \@items,
        next_page => $next_page,
    };
}

1;
