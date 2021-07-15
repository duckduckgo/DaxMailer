use strict;
use warnings;
package DaxMailer::Script::DeletePCCGraduated;

use Moo;
use Data::Dumper;

with 'DaxMailer::Base::Script::Service';

sub go {
    my ( $self ) = @_;

    my $campaigns = config()->{campaigns};
    
    # Delete Privacy Crash Course graduates
    for my $campaign ( sort keys %{ $campaigns } ) {
        my @mail_map = (
            'v',
            sort { $a <=> $b }
            grep { /^[0-9]+$/ }
            grep { !$campaigns->{ $campaign }->{mails}->{ $_ }->{oneoff} }
            keys %{ $campaigns->{ $campaign }->{mails} }
        );

        my $mail = $mail_map[ $#mail_map - 1 ];

        # Should be 26 or higher
        warn Dumper( $mail );

        my @subscribers = rset('Subscriber')
            ->campaign( $campaign )
            ->subscribed
            ->mail_sent( $campaign, $mail  )
            ->all;    

        for my $subscriber ( @subscribers ) {
            warn "Deleting graduated user $subscriber";
            $subscriber->delete();
        }
    }


    # Delete subscribers who signed up more than 28 weeks ago
    my @old_subscribers = rset('Subscriber')
        ->by_days_ago(203)
        ->all;

    for my $old_subscriber ( @old_subscribers) {
        warn "Deleting old subscriber $old_subscriber";
        $old_subscriber->delete();
    }
}

1;
