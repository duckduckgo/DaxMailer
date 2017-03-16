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
