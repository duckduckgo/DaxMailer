package DaxMailer::Schema::ResultSet::Subscriber::Bounce;

use Moo;
extends 'DaxMailer::Schema::ResultSet';

use DBI;

has legacy_dbh => ( is => 'lazy' );
sub _build_legacy_dbh {
    my ( $self ) = @_;
    return unless $self->app->config->{ legacy_db_dsn };
    DBI->connect( @{ $self->app->config }{qw/
        legacy_db_dsn
        legacy_db_user
        legacy_db_password
    /} );
};

sub _legacy_bounce {
    my ( $self, $type, @emails ) = @_;
    return unless scalar @emails;
    return unless $self->legacy_dbh;

    my $column = $self->legacy_dbh->quote_identifier( $type );
    my $binds = join ',', map { '?' } @emails;

    $self->legacy_dbh->do(
       "UPDATE subscriber
        SET    $column = 1
        WHERE  email_address IN ( $binds )",
        undef, @emails
    );
};

sub legacy_unsub {
    my ( $self, $email ) = @_;
    return unless $self->legacy_dbh;

    $self->legacy_dbh->do(
       "UPDATE subscriber
        SET    unsubscribed = 1
        WHERE  email_address = ?",
        undef, ( $email )
    );
}

sub handle_bounces {
    my ( $self, $message ) = @_;
    my $update_params;
    my @emails;
    if ( $message->{notificationType} eq 'Bounce' && $message->{bounce}->{bounceType} eq 'Permanent' ) {
        $update_params = { bounced => 1 };
        push @emails, map { $_->{emailAddress} } @{$message->{bounce}->{bouncedRecipients}};
        $self->_legacy_bounce( 'bounced', @emails );
    }
    elsif ( $message->{notificationType} eq 'Complaint' ){
        $update_params = { complaint => 1 };
        push @emails, map { $_->{emailAddress} } @{$message->{complaint}->{complainedRecipients}};
        $self->_legacy_bounce( 'complaint', @emails );
    }

    return { ok => 1 } if !$update_params || !@emails;

    for my $email (@emails) {
        $self->update_or_create({ email_address => lc($email), %{ $update_params } });
    }

    return { ok => 1 };
}

sub bounced {
    my ( $self ) = @_;
    $self->search_rs({ -or => [
        $self->me('bounced')      => 1,
        $self->me('complaint')    => 1,
        $self->me('unsubscribed') => 1
    ] });
}

sub check {
    my( $self, $email ) = @_;
    $self->bounced
         ->search({ email_address => lc($email) })
         ->one_row;
}

1;
