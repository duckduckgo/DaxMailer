package DaxMailer::Schema::ResultSet::Subscriber;

use Moo;
extends 'DaxMailer::Schema::ResultSet';

use DateTime;
use DateTime::Duration;
use String::Truncate qw/ trunc /;

has stringutils => ( is => 'lazy' );
sub _build_stringutils {
    require DaxMailer::Util::Strings;
    DaxMailer::Util::Strings->new;
}

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

sub add_from_post {
    my ( $self, $params ) = @_;

    # Silently reject friends signups
    return 1 if ( lc($params->{campaign}) eq 'c' && !$ENV{DAXMAILER_MAIL_TEST} );

    $params->add(
        campaign => 'b'
    ) if $params->{tips} && !$params->{campaign};

    my $unsubscribed = 0;
    $unsubscribed = 1 if (
        $params->{from} &&
        $self->stringutils->looks_like_contains_real_domains(
            $params->{from}
        )
    );
    my @emails;
    {
        no warnings 'uninitialized';
        @emails =
        grep { $_ }
        map  { scalar Email::Valid->address( $_ ) }
        ( split( ',', $params->{to} ), $params->{email} );
    }

    return unless @emails;

    my $extra = {};
    $extra->{from} =
        trunc( $params->{from}, 50, { at_space => 1 } )
        if $params->{from};
    $extra->{template} = $params->{template} if $params->{template};

    my $campaigns = [ $params->{campaign} ];
    push @{ $campaigns }, $self->app->config->{campaigns}->{ $params->{campaign} }->{base}
        if $self->app->config->{campaigns}->{ $params->{campaign} }->{base};

    for my $email ( @emails ) {
        my $u = $unsubscribed;
        $u = 1 if (
            !$u &&
            $self->stringutils->recipient_probably_not_interested( $email )
        );
        my $exists = $self->exists( $email, $campaigns );
        next if $exists;

        $self->create( {
            email_address => $email,
            campaign      => $params->{campaign},
            flow          => $params->{flow},
            extra         => $extra,
            unsubscribed  => $u,
            verified      => $self->app->config->{campaigns}->{ $params->{campaign} }->{single_opt_in} // 0,
        } );
    }

    return 1;
}

1;
