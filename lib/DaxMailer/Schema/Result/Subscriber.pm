package DaxMailer::Schema::Result::Subscriber;

use Moo;
extends 'DaxMailer::Schema::Result';
use DBIx::Class::Candy;

use URI;
use Digest::SHA1;

table 'subscriber';

primary_column email_address => { data_type => 'text' };
primary_column campaign      => { data_type => 'text' };

column verified     => { data_type => 'int', default_value => 0 };
column unsubscribed => { data_type => 'int', default_value => 0 };
column flow         => { data_type => 'text', is_nullable => 1 };
column v_key        => { data_type => 'text' };
column u_key        => { data_type => 'text' };
column created      => { data_type => 'timestamptz', set_on_create => 1 };
column extra        => {
    data_type => 'text',
    serializer_class => 'JSON',
    default_value => '{}',
};

has_many logs => 'DaxMailer::Schema::Result::Subscriber::MailLog' => {
    'foreign.email_address' => 'self.email_address',
    'foreign.campaign'      => 'self.campaign',
};

has_many bounce => 'DaxMailer::Schema::Result::Subscriber::Bounce' => {
    'foreign.email_address' => 'self.email_address',
} => {
    join_type     => "LEFT",
};

around new => sub {
    my $orig = shift;
    my $self = shift;
    $_[0]->{v_key} ||= _key();
    $_[0]->{u_key} ||= _key();
    $orig->( $self, @_ );
};

sub _key {
    Digest::SHA1::sha1_hex( rand() . $$ . {} . time );
}

sub _url {
    my ( $self, $type ) = @_;
    my $u = URI->new( $self->app
        ? $self->app->config->{base_url}
        : 'http://localhost'
    );
    $u->path(
        sprintf "/s/%s/%s/%s/%s",
        ( $type eq 'u' ? 'u' : 'v' ),
        $self->campaign,
        $self->email_address =~ s/\@/%40/gr,
        ( $type eq 'u' ? $self->u_key : $self->v_key )
    );
    return $u->canonical->as_string;
}

sub verify_url {
    my ( $self ) = @_;
    $self->_url( 'v' );
}

sub unsubscribe_url {
    my ( $self ) = @_;
    $self->_url( 'u' );
}

sub verify {
    my ( $self, $key ) = @_;
    return $self->verified if $self->verified;
    return unless ( $key eq $self->v_key );
    $self->update({
        verified => 1,
    });
}

sub unsubscribe {
    my ( $self, $key ) = @_;
    $self->delete()
        if ( $key eq $self->u_key );
}

1;
