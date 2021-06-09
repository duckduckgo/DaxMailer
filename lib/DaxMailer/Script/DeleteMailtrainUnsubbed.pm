use strict;
use warnings;
package DaxMailer::Script::DeleteMailtrainUnsubbed;

use Moo;

with 'DaxMailer::Base::Script::Service';

sub go {
    my ( $self ) = @_;

    rset('Subscriber::Mailtrain')->search(
        { 'unsubscribed' => 1 }
    )->process_subscription('delete');
}

1;
