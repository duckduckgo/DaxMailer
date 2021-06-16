use strict;
use warnings;
package DaxMailer::Script::DeleteMailtrainUnsubbed;

use Moo;

with 'DaxMailer::Base::Script::Service';

sub go {
    my ( $self ) = @_;

    my @unsubbed_users = rset('Subscriber::Mailtrain')->search(
        { operation => 'unsubscribe' }
    );

    for my $unsubbed ( @unsubbed_users ) {
        rset('Subscriber::Mailtrain')->unsubscribe( $unsubbed->email_address );
    }
}

1;
