package LogProcessor;
use Moo::Role;

# 「next_logというメソッドを必ず持っていること」という契約
requires 'next_log';

1;
