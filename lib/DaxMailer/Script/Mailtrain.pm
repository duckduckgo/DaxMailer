use strict;
use warnings;
package DaxMailer::Script::Mailtrain;

use Moo;

with qw/
    DaxMailer::Base::Script::Service
/;

sub go {
    my ( $self ) = @_;
    rset('Subscriber::Mailtrain')->process;
}

1;
