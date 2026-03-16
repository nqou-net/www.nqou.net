package OrderState;
use Moo::Role;

requires 'process_payment';
requires 'ship_item';
requires 'cancel';
requires 'status_name';

1;
