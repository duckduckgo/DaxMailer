use strict;
use warnings;
package DaxMailer::Script::DeleteUnsubbed;

use Moo;

with 'DaxMailer::Base::Script::Service';

sub go {
    my ( $self ) = @_;

    rset('Subscriber')->unsubscribed->delete();
}

1;
