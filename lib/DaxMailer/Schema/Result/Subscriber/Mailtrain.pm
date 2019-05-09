package DaxMailer::Schema::Result::Subscriber::Mailtrain;

use Moo;
extends 'DaxMailer::Schema::Result';
use DBIx::Class::Candy;

table 'subscriber_mailtrain';

primary_column email_address => { data_type => 'text' };
primary_column operation     => { data_type => 'text' };

column updated => { data_type => 'timestamptz', set_on_create => 1, set_on_update => 1 };
column created => { data_type => 'timestamptz', set_on_create => 1 };

column processed => { data_type => 'int', default_value => 0 };

1;
