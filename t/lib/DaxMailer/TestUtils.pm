package t::lib::DaxMailer::TestUtils;
use strict;
use warnings;

use DaxMailer::Base::Web::Common;
use Try::Tiny;
use DateTime;

sub deploy {
    my ( $opts, $schema ) = @_;
    my $success = 1;
    try {
        if ($ENV{DAXMAILER_DB_DSN} =~ /^dbi:SQLite/) {
            my $fn = $ENV{DAXMAILER_DB_DSN} =~ s/.*dbname=(.*)/$1/r;
            unlink $fn if $fn;
            if ( $schema ) {
                $schema->deploy({
                    add_drop_table => $opts->{drop} || 0
                });
            }
            else {
                DaxMailer::Schema->connect($ENV{DAXMAILER_DB_DSN})->deploy({
                    add_drop_table => $opts->{drop} || 0
                });
            }
        }
    }
    catch {
        $success = 0;
    };
    return $success;
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
