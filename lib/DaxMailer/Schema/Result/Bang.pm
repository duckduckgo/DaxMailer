package DaxMailer::Schema::Result::Bang;

use Moo;
extends 'DaxMailer::Schema::Result';
use DBIx::Class::Candy;
use Email::Valid;

table 'bang';

primary_column command => { data_type => 'text' };
primary_column url     => { data_type => 'text' };

column email_address   => { data_type => 'text', is_nullable => 1 };

might_have subscriber => 'DaxMailer::Schema::Result::Subscriber' => sub {
    my ( $self, $foreign ) = @{ $_[0] }{qw/ self_alias foreign_alias /};
    return +{
      "$self.email_address" => { '!=' => undef },
      "$foreign.email_address" => "$self.email_address",
      "$foreign.campaign"      => \'newbang',
    }
};

around new => sub {
    my $orig = shift;
    my $self = shift;
    $_[0]->{email_address} = Email::Valid->address( $_[0]->{email_address} ) // '';
    $orig->( $self, @_ );
};

after new => sub {
    use DDP; p @_;
    my ( $self ) = @_;
};

1;
