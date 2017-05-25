package DaxMailer::Schema::Result::Subscriber::MailLog;

use Moo;
extends 'DaxMailer::Schema::Result';
use DBIx::Class::Candy;

table 'subscriber_maillog';

primary_column email_address => { data_type => 'text' };
primary_column campaign      => { data_type => 'text' };
primary_column email_id      => { data_type => 'text' };

column sent => {
    data_type => 'timestamptz',
    set_on_create => 1,
};

belongs_to subscriber => 'DaxMailer::Schema::Result::Subscriber' => {
    'foreign.email_address' => 'self.email_address',
    'foreign.campaign'      => 'self.campaign',
};

1;
