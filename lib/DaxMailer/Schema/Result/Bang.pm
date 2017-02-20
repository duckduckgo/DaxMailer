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
column site_name       => { data_type => 'text' };
column category_id     => { data_type => 'integer' };

might_have subscriber => 'DaxMailer::Schema::Result::Subscriber' => sub {
    my ( $self, $foreign ) = @{ $_[0] }{qw/ self_alias foreign_alias /};
    return +{
        "$self.email_address"    => { '!=' => undef },
        "$foreign.email_address" => "$self.email_address",
        "$foreign.campaign"      => \'newbang',
    };
};

has_one category => 'DaxMailer::Schema::Result::Bang::Category' => 'id';

around new => sub {
    my $orig = shift;
    my $self = shift;
    $_[0]->{email_address} = Email::Valid->address( $_[0]->{email_address} ) // '';
    $_[0]->{comments} =~ s/\s+/ /g;
    $orig->( $self, @_ );
};

after new => sub {
    use DDP; p @_;
    my ( $self ) = @_;
};

1;
