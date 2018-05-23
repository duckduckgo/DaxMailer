package DaxMailer::Schema::ResultSet::Subscriber;

use Moo;
extends 'DaxMailer::Schema::ResultSet';

use DateTime;
use DateTime::Duration;

sub campaign {
    my ( $self, $c ) = @_;
    $self->search_rs( { $self->me('campaign') => $c } );
}

sub subscribed {
    my ( $self ) = @_;
    $self->search_rs( { $self->me('unsubscribed') => 0 } );
}

sub unsubscribed {
    my ( $self ) = @_;
    $self->search_rs( { $self->me('unsubscribed') => 1 } );
}

sub verified {
    my ( $self ) = @_;
    $self->search_rs( { $self->me('verified') => 1 } );
}

sub unverified {
    my ( $self, $single_opt_in ) = @_;
    return $self->verified if $single_opt_in;
    $self->search_rs( { $self->me('verified') => 0 } );
}

sub bounced {
    my ( $self ) = @_;
    $self->search_rs({
        'me.email_address' => {
            -in => $self->search_related_rs('bounce')
                            ->bounced
                            ->get_column('email_address')
                            ->as_query
        }
    });
}

sub unbounced {
    my ( $self ) = @_;
    $self->search_rs({
        'me.email_address' => {
            -not_in => $self->search_related_rs('bounce')
                            ->bounced
                            ->get_column('email_address')
                            ->as_query
        }
    });
}

sub mail_unsent {
    my ( $self, $campaign, $email ) = @_;
    $self->search_rs( {
        'me.email_address' => { -not_in => \[
                'SELECT email_address
                 FROM subscriber_maillog
                 WHERE campaign = ?
                 AND email_address = me.email_address
                 AND email_id = ?',
                ( $campaign, $email )
            ],
        }
    } );
}

sub mail_sent_days_ago {
    my ( $self, $campaign, $email, $days ) = @_;
    my $sent= $self->format_datetime( DateTime->now->subtract( days => ( $days - 1 ) )->truncate( to => 'day' ) );
    $self->search_rs( {
        'me.email_address' => { -in => \[
                'SELECT email_address
                 FROM subscriber_maillog
                 WHERE campaign = ?
                 AND email_address = me.email_address
                 AND email_id = ?
                 AND sent < ?',
                ( $campaign, $email, $sent )
            ],
        }
    } );
}

sub verification_mail_unsent_for {
    my ( $self, $campaign ) = @_;
    $self->search_rs( {
        'me.email_address' => { -not_in => \[
                'SELECT email_address
                 FROM subscriber_maillog
                 WHERE campaign = ?
                 AND email_address = me.email_address
                 AND email_id = \'v\'',
                $campaign
            ],
        }
    } );
}

sub join_latest_email {
    my ( $self ) = @_;
    $self->search_rs( {
        'logs.email_id' => { -in => \[
            'SELECT email_id
             FROM   subscriber_maillog
             WHERE  campaign = me.campaign
             AND    email_address = me.email_address
             ORDER BY sent DESC
             LIMIT 1'
        ], }
    },
    {
        '+select' => 'logs.email_id',
        '+as'     => 'email_id',
        join => [ 'logs' ]
    } );
}

sub by_days_ago {
    my ( $self, $days ) = @_;
    my $today = DateTime->now->truncate( to => 'day' );
    my $end = $self->format_datetime(
        $today->subtract( days => ( $days - 1 ) )
    );
    my $start = $self->format_datetime(
        $today->subtract( days => 1 )
    );

    $self->search_rs( {
        created => { -between => [ $start, $end ] }
    } );
}

sub exists {
    my ( $self, $email, $campaigns ) = @_;
    $self->search( \[ 'LOWER( email_address ) = ?', lc( $email ) ] )
         ->search( { campaign => $campaigns } )
         ->one_row;
}

1;
