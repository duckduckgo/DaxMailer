use strict;
use warnings;
package DaxMailer::Script::DeletePCCGraduated;

use Moo;

with 'DaxMailer::Base::Script::Service';

sub go {
    my ( $self ) = @_;

    my $campaigns = config()->{campaigns};
    for my $campaign ( sort keys %{ $campaigns } ) {
        my @mail_map = (
            'v',
            sort { $a <=> $b }
            grep { /^[0-9]+$/ }
            grep { !$campaigns->{ $campaign }->{mails}->{ $_ }->{oneoff} }
            keys %{ $campaigns->{ $campaign }->{mails} }
        );
        my $mail = $mail_map[ $#mail_map - 1 ];
        my @subscribers = rset('Subscriber')
            ->campaign( $campaign )
            ->subscribed
            ->mail_sent( $campaign, $mail  )
            ->all;
            
            
        for my $subscriber ( @subscribers ) {
            $subscriber->delete();
        }
    }
}

1;
