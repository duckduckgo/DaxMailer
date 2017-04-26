use strict;
use warnings;
package DaxMailer::Script::MigrateDDGC;

use Moo;
use DBI;
use Carp;
use Try::Tiny;

with 'DaxMailer::Base::Script::Service';

has ddgc_dbh => ( is => 'lazy' );
sub _build_ddgc_dbh {
    my ( $self ) = @_;
    my $dbh = DBI->connect( @{ config() }{qw/
        legacy_db_dsn
        legacy_db_user
        legacy_db_password
    /} );
    croak "Unable to open legacy db" unless $dbh;
    return $dbh;
}

sub go {
    my ( $self ) = @_;

    my $schema = schema('default');
    my $guard = $schema->txn_scope_guard;

    my $sth = $self->ddgc_dbh->prepare('SELECT * FROM subscriber');
    $sth->execute;
    while ( my $row = $sth->fetchrow_hashref ) {
        my $email = Email::Valid->address($row->{email_address});
        next unless $email;
        my $subscriber = rset('Subscriber')->update_or_create({
            email_address => $email,
            unsubscribed  => $row->{unsubscribed},
            verified      => $row->{verified},
            campaign      => $row->{campaign},
            created       => $row->{created},
            v_key         => $row->{v_key},
            u_key         => $row->{u_key},
            flow          => $row->{flow},
            extra         => {},
        });
        $subscriber && $subscriber->update_or_create_related( 'logs', { email_id => 'v' } );
        if ( $row->{bounced} || $row->{complaint} ) {
            rset('Subscriber::Bounce')->update_or_create({
                email_address => $email,
                bounced       => $row->{bounced},
                complaint     => $row->{complaint},
            });
        }
        my $sth2 = $self->ddgc_dbh->prepare('SELECT * FROM subscriber_maillog where email_address = ?');
        $sth2->execute( $email );
        while ( my $row2 = $sth2->fetchrow_hashref ) {
            try {
                rset('Subscriber::MailLog')->update_or_create({
                    email_address => $row2->{email_address},
                    campaign      => $row2->{campaign},
                    email_id      => $row2->{email_id},
                    sent          => $row2->{sent},
                });
            } catch {
                die sprintf "Unable to insert log entry %s, %s : %s",
                    $row->{email_address}, $row->{email_id}, $_;
            };
        }
    }


    $guard->commit;
}

1;
