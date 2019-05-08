package DaxMailer::Schema::ResultSet::Subscriber::Mailtrain;

use Moo;
extends 'DaxMailer::Schema::ResultSet';

has mailtrain => ( is => 'lazy' );
sub _build_mailtrain {
    my ( $self ) = @_;
    require Mailtrain::API;
    Mailtrain::API->new(
        host  => $self->app->config->{mailtrain_host},
        port  => $self->app->config->{mailtrain_port},
        list  => $self->app->config->{mailtrain_list},
        token => $self->app->config->{mailtrain_access_token},
    );
}

sub subscription {
    my ( $self, $method ) = @_;

    my $result = $self->mailtrain->$method(
        map { $_->email_address } $self->all
    );

    warn sprintf(
        "Unable to %s %s : %s",
         $method, $_->{email}, $_->{reason}
    ) for (@{ $result->{fail} });

    $self->search({
        email_address => { -in => $result->{success} }
    })->update({ processed => 1 });
}

sub process {
    my ( $self ) = @_;
    $self->search({ processed => 0, operation => $_ })->subscription( $_ )
        for ( qw/ subscribe unsubscribe / );
}

1;
