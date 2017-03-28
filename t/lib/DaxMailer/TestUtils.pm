package t::lib::DaxMailer::TestUtils;
use strict;
use warnings;

use DaxMailer::Base::Web::Common;
use Try::Tiny;
use DateTime;
use DBI;
use DateTime;

my $legacy_dbh;

sub deploy {
    my ( $opts, $schema ) = @_;
    my $success = 1;
    try {
        if ($ENV{DAXMAILER_DB_DSN} =~ /^dbi:SQLite/) {
            $schema //= DaxMailer::Schema->connect(
                $ENV{DAXMAILER_DB_DSN}, '', '',
                { PrintError => 1, RaiseError => 1, AutoCommit => 1 }
            );
            $schema->deploy({
                add_drop_table => $opts->{drop} || 0
            });
        }
    }
    catch {
        $success = 0;
    };
    return $success;
    }

sub deploy_legacy {
    $legacy_dbh = DBI->connect($ENV{LEGACY_DB_DSN}) or return;
    return $legacy_dbh->do( q{
        CREATE TABLE subscriber (
            email_address text NOT NULL,
            campaign text NOT NULL,
            created timestamptz NOT NULL,
            verified integer DEFAULT 0 NOT NULL,
            unsubscribed integer DEFAULT 0 NOT NULL,
            bounced integer DEFAULT 0 NOT NULL,
            complaint integer DEFAULT 0 NOT NULL
        )
    } );
}

sub add_legacy_subscriber {
    my ( $email_address, $campaign ) = @_;
    return unless $legacy_dbh;
    return $legacy_dbh->do( q{
        INSERT INTO
               subscriber
               ( email_address, campaign, created )
        VALUES ( ?, ?, ? )
    }, undef, ( $email_address, $campaign, DateTime->now->ymd ) );
}

sub subscriber_bounced {
    my ( $email_address, $campaign ) = @_;
    return $legacy_dbh->selectrow_array( q{
        SELECT bounced
        FROM   subscriber
        WHERE  email_address = ?
          AND  campaign = ?
    }, undef, ( $email_address, $campaign ) );
}

sub ok {
    +{
        ok => 1,
        @_,
    }
}

sub not_ok {
    +{
        ok => 0,
        msg => shift,
        @_,
    }
}

1;
