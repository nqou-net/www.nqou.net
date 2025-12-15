use strict;
use warnings;
use feature 'say';

eval { require Moo; };
say $@ ? "❌ Moo not found" : "✅ Moo OK";

eval { require Type::Tiny; };
say $@ ? "❌ Type::Tiny not found" : "✅ Type::Tiny OK";

eval { require Test2::V0; };
say $@ ? "❌ Test2::Suite not found" : "✅ Test2::Suite OK";

eval { require namespace::clean; };
say $@ ? "❌ namespace::clean not found" : "✅ namespace::clean OK";

eval { require JSON::MaybeXS; };
say $@ ? "⚠️  JSON::MaybeXS not found (optional)" : "✅ JSON::MaybeXS OK";
