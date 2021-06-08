use strict;
use warnings;
package DaxMailer::Script::DeleteUnsubbed;

use Moo;

with 'DaxMailer::Base::Script::Service';

sub go {
    my ( $self ) = @_;

    my $unsubbed = rset('Subscriber::Bounce')->search(
        { 'unsubscribed' => 1 }
    );
}

1;
