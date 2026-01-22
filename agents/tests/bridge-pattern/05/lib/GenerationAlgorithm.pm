# GenerationAlgorithm.pm - アルゴリズムのRole
package GenerationAlgorithm;
use v5.36;
use Moo::Role;

# サブクラスで実装必須
requires 'generate';

1;
