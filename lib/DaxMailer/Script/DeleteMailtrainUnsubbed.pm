use strict;
use warnings;
package DaxMailer::Script::DeleteMailtrainUnsubbed;

use Moo;

with 'DaxMailer::Base::Script::Service';

sub go {
    my ( $self ) = @_;

    my @unsubbed_users = rset('Subscriber::Mailtrain')->search(
        { operation => 'unsubscribe' }
    )->process_subscription( qw/ unsubscribe / ); # This will now delete the user too
}

1;
