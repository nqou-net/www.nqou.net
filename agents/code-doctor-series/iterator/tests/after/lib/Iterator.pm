package Iterator;
use v5.36;

# Interface Definition
# Subclasses must implement these methods

sub has_next($self) { die "Method 'has_next' must be implemented by subclass" }
sub next($self)     { die "Method 'next' must be implemented by subclass" }

1;
