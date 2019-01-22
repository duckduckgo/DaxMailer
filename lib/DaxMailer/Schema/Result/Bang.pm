package DaxMailer::Schema::Result::Bang;

use Moo;
extends 'DaxMailer::Schema::Result';
use DBIx::Class::Candy;
use Email::Valid;

table 'bang';

primary_column command => { data_type => 'text' };
primary_column url     => { data_type => 'text' };

column email_address   => { data_type => 'text', is_nullable => 1 };
column comments        => { data_type => 'text', is_nullable => 1 };
column example_search  => { data_type => 'text', is_nullable => 1, default_value => 'hello' };
column site_name       => { data_type => 'text' };
column category_id     => { data_type => 'integer' };
column note            => { data_type => 'text', is_nullable => 1 };

column moderated       => { data_type => 'integer', default_value => 0 };
column created         => { data_type => 'timestamptz', set_on_create => 1, default_value => '2019-01-01' };

belongs_to category => 'DaxMailer::Schema::Result::Bang::Category' => 'category_id';

around new => sub {
    my $orig = shift;
    my $self = shift;
    $_[0]->{email_address} = Email::Valid->address( $_[0]->{email_address} ) // '';
    $_[0]->{comments} =~ s/\s+/ /g;
    $orig->( $self, @_ );
};

1;
