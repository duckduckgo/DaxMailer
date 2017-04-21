use strict;
use warnings;
package DaxMailer::Script::VerifyLastSend;

use Moo;
use MooX::Options;

use DateTime;
use DateTime::Duration;

with 'DaxMailer::Base::Script::Service';

has hours => (
    is => 'ro',
    default => sub { 2 },
);

sub go {
    my $x_hours_ago = schema('default')->storage->datetime_parser->format_datetime(
        DateTime->now->subtract( hours => $_[0]->hours )
    );
    my $sent = rset('Subscriber::MailLog')->search({
        sent => { '>=' => $x_hours_ago }
    })->one_row;
    if ( $sent ) {
        printf "Success\n";
        exit 0;
    } else {
        printf "Failure\n";
        exit 2;
    }
}

1;
