package DaxMailer::Schema::Result::Subscriber::Bounce;

use Moo;
extends 'DaxMailer::Schema::Result';
use DBIx::Class::Candy;

table 'subscriber_bounce';

primary_column email_address => { data_type => 'text' };

column bounced      => { data_type => 'int', default_value => 0 };
column complaint    => { data_type => 'int', default_value => 0 };

1;
