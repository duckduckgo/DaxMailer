package DaxMailer::Schema::ResultSet::Subscriber::Mailtrain;

use Moo;
extends 'DaxMailer::Schema::ResultSet';

use Try::Tiny;

has process_days => ( is => 'ro', default => sub { 7 } );

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

sub process_subscription {
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
    my $dt = $self->format_datetime(
        DateTime->now->subtract(
            days => $self->process_days
        )->truncate( to => 'day' )
    );
    $self->search({
        processed => 0, operation => $_,
        created => { '>' => $dt },
    })->process_subscription( $_ )
        for ( qw/ subscribe unsubscribe / );
}

sub manage_subscription {
    my ( $self, $operation, $email ) = @_;
    return unless $email;
    try {
        my $subscriber = $self->find_or_create( {
            email_address => $email,
            operation => $operation,
        } );
        $subscriber->processed( 0 );
        $subscriber->update;
    } catch {
        warn "sprintf Unable to unsub %s", $email;
        return 0;
    };
}

sub unsubscribe {
    my ( $self, $email ) = @_;
    $self->manage_subscription( unsubscribe => $email );
}

sub subscribe {
    my ( $self, $email ) = @_;
    $self->manage_subscription( subscribe => $email );
}

1;
