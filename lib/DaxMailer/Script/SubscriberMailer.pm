use strict;
use warnings;
package DaxMailer::Script::SubscriberMailer;

use DateTime;
use Moo;
use Hash::Merge::Simple qw/ merge /;
use String::Truncate qw/ trunc /;
use File::Spec::Functions;
use File::Slurper qw/ read_text /;
use Carp;

with 'DaxMailer::Base::Script::Service',
     'DaxMailer::Base::Script::ServiceEmail';

has newsletter_file => ( is => 'lazy' );
sub _build_newsletter_file {
    my $file_store = config()->{file_store};
    croak "No persistent store configured" unless $file_store;
    catfile( $file_store, 'newsletter.txt' );
}

has campaigns => ( is => 'lazy' );
sub _build_campaigns {
    # Should this be external JSON?
    my $campaigns = +{
        'a' => {
            single_opt_in => 1,
            live => 1,
            verify => {
                subject => 'Tracking in Incognito?',
                template => 'email/a/1.tx'
            },
            verify_page_template => 'email/a/verify.tx',
            unsub_page_template  => 'email/a/unsub.tx',
            layout => 'email/a/layout.tx',
            mails => {
                2 => {
                    days     => 2,
                    subject  => 'Are Ads Following You?',
                    template => 'email/a/2.tx',
                },
                3 => {
                    days     => 4,
                    subject  => 'Are Ads Costing You Money?',
                    template => 'email/a/3.tx',
                },
                4 => {
                    days     => 6,
                    subject  => 'Have You Deleted Your Google Search History Yet?',
                    template => 'email/a/4.tx',
                },
                5 => {
                    days     => 8,
                    subject  => 'Is Your Data Being Sold?',
                    template => 'email/a/5.tx',
                },
                6 => {
                    days     => 11,
                    subject  => 'Who Decides What Websites You Visit?',
                    template => 'email/a/6.tx',
                },
                7 => {
                    days     => 12,
                    subject  => 'Was This Useful?',
                    template => 'email/a/7.tx',
                },
            }
        },
        'b' => {
            base => 'a',
            single_opt_in => 1,
            verify => {
                subject => 'Tracking in Incognito?',
                template => 'email/a/1b.tx'
            }
        },
        'c' => {
            base => 'a',
            single_opt_in => 0,
            verify_layout => 'email/a/verify_layout.tx',
            template_map => 'c',
            mails => {
                1 => {
                    days     => 1,
                    subject => 'Tracking in Incognito?',
                    template => 'email/a/1c.tx',
                },
            }
        },
        'friends' => {
            single_opt_in => 1,
            plain_text => 1,
            layout => 'email/friends/layout.tx',
        }
    };

    for my $campaign ( keys %{ $campaigns } ) {
        if ( my $base = $campaigns->{ $campaign }->{base} ) {
            if ( $campaigns->{ $base } ) {
                $campaigns->{ $campaign } = merge( $campaigns->{ $base }, $campaigns->{ $campaign } );
            }
            else {
                die "Base $base does not exist - cannot build campaign $campaign"
            }
        }
    };

    return $campaigns;
}

# Map email selection => filename explicitly
# We don't want to build paths from user input
has template_map => ( is => 'lazy' );
sub _build_template_map {
    +{
        'c' => {
            1 => {
                subject => sub {
                    sprintf "Privacy Tip from %s",
                    $_[0]->extra->{from}
                },
                template => 'email/a/v1.tx',
            },
            2 => {
                subject =>  sub {
                    sprintf "Privacy Tip from %s",
                    $_[0]->extra->{from}
                },
                template => 'email/a/v2.tx',
            },
            3 => {
                subject => sub {
                    sprintf "Privacy Tip from %s",
                    $_[0]->extra->{from}
                },
                template => 'email/a/v3.tx',
            },
        }
    }
}

sub email {
    my ( $self, $log, $subscriber, $subject, $template, $layout, $verified ) = @_;

    my $status = $self->smtp->send( {
        to       => $subscriber->email_address,
        verified => $verified
                    || ( $subscriber->verified && !$subscriber->unsubscribed ),
        from     => '"DuckDuckGo Dax" <dax@duckduckgo.com>',
        subject  => $subject,
        template => $template,
        layout   => $layout,
        content  => {
            subscriber => $subscriber,
            title => $subject,
        }
    } );

    if ( $status->{ok} ) {
        $subscriber->update_or_create_related( 'logs', { email_id => $log } );
    }

    return $status;
}

sub email_plaintext {
    my ( $self, $log, $subscriber, $subject, $content, $layout, $verified ) = @_;

    my $status = $self->smtp->send_plaintext( {
        to       => $subscriber->email_address,
        verified => $verified
                    || ( $subscriber->verified && !$subscriber->unsubscribed ),
        from     => '"DuckDuckGo Dax" <dax@duckduckgo.com>',
        subject  => $subject,
        template => $layout,
        content  => {
            body => $content,
            subscriber => $subscriber,
        }
    } );

    if ( $status->{ok} ) {
        $subscriber->update_or_create_related( 'logs', { email_id => $log } );
    }

    return $status;
}

sub execute {
    my ( $self ) = @_;

    for my $campaign ( keys %{ $self->campaigns } ) {
        next if !$self->campaigns->{ $campaign }->{live};
        for my $mail ( keys %{ $self->campaigns->{ $campaign }->{mails} } ) {
            my @subscribers = rset('Subscriber')
                ->campaign( $campaign )
                ->subscribed
                ->verified
                ->unbounced
                ->mail_unsent( $campaign, $mail )
                ->by_days_ago( $self->campaigns->{ $campaign }->{mails}->{ $mail }->{days} )
                ->all;

            for my $subscriber ( @subscribers ) {
                $self->email(
                    $mail,
                    $subscriber,
                    $self->campaigns->{ $campaign }->{mails}->{ $mail }->{subject},
                    $self->campaigns->{ $campaign }->{mails}->{ $mail }->{template},
                    $self->campaigns->{ $campaign }->{layout},
                );
            }
        }
    }

    return $self->smtp->transport;
}

sub _send_verify_email {
    my ( $self, $subscriber, $campaign ) = @_;
    my ( $template, $subject );
    if ( $subscriber->extra && ( my $st = $subscriber->extra->{template} ) ) {
        my $tm = $self->campaigns->{ $campaign }->{template_map};
        if ( my $t = $self->template_map->{ $tm }->{ $st } ) {
            $template = $t->{template};

            $subject = ref $t->{subject} eq 'CODE'
                ? $t->{subject}->( $subscriber )
                : $t->{subject}

        }
    }
    $subject ||= $self->campaigns->{ $campaign }->{verify}->{subject};
    $template ||= $self->campaigns->{ $campaign }->{verify}->{template};

    my $layout = $self->campaigns->{ $campaign }->{verify_layout}
        || $self->campaigns->{ $campaign }->{layout};

    $self->email(
        'v',
        $subscriber,
        $subject,
        $template,
        $layout,
        1
    );
}

sub verify {
    my ( $self ) = @_;

    for my $campaign ( keys %{ $self->campaigns } ) {
        next if !$self->campaigns->{ $campaign }->{live};
        my @subscribers = rset('Subscriber')
            ->campaign( $campaign )
            ->unverified( $self->campaigns->{ $campaign }->{single_opt_in} )
            ->verification_mail_unsent_for( $campaign )
            ->all;

        for my $subscriber ( @subscribers ) {
            $self->_send_verify_email( $subscriber, $campaign );
        }
    }

    return $self->smtp->transport;
}

sub testrun {
    my ( $self, $campaign, $email, $extra ) = @_;
    $extra //= {};

    # Instantiating an in-memory schema is easier than trying to
    # create mock objects or deal with existing live data matching
    # the requested email address.
    my $schema = DaxMailer::Schema->connect('dbi:SQLite:dbname=:memory:');
    $schema->deploy;

    my $subscriber = $schema->resultset('Subscriber')->create( {
        email_address => $email,
        campaign      => $campaign,
        verified      => 1,
    } );

    if ( my $tm = $self->campaigns->{ $campaign }->{template_map} ) {
        for my $template ( sort keys $self->template_map->{ $tm } ) {
            $subscriber->extra({
                    from =>
                        trunc( $extra->{from}, 512, { at_space => 1 } )
                        || 'Your pal!',
                    template => $template
                });
            $self->_send_verify_email( $subscriber, $campaign );
        }
    }
    else {
        $self->_send_verify_email( $subscriber, $campaign );
    }

    goto VERIFYONLY if $extra->{verify_only};

    my $mails = $self->campaigns->{ $campaign }->{mails};
    for my $mail ( sort keys %{ $mails } ) {
        $self->email(
            $mail,
            $subscriber,
            $mails->{ $mail }->{subject},
            $mails->{ $mail }->{template},
            $self->campaigns->{ $campaign }->{layout},
            1, 1
        );
    }

VERIFYONLY:
    return ( $self->smtp->transport, $subscriber );
}

sub add {
    my ( $self, $params ) = @_;
    my @emails;
    @emails =
        grep { $_ }
        map  { my $v = Email::Valid->address( $_ ) ; $v }
        split ',', $params->{to}
        if $params->{to};
    push @emails, ( grep { $_ } Email::Valid->address($params->{email}) )[0];

    return if scalar @emails < 1;

    my $extra = {};
    $extra->{from} =
        trunc( $params->{from}, 512, { at_space => 1 } )
        if $params->{from};
    $extra->{template} = $params->{template} if $params->{template};

    my $campaigns = [ $params->{campaign} ];
    push @{ $campaigns }, $self->campaigns->{ $params->{campaign} }->{base}
        if $self->campaigns->{ $params->{campaign} }->{base};

    for my $email ( @emails ) {
        my $exists = rset('Subscriber')->exists( $email, $campaigns );
        next if $exists;

        rset('Subscriber')->create( {
            email_address => $email,
            campaign      => $params->{campaign},
            flow          => $params->{flow},
            extra         => $extra,
            verified      => $self->campaigns->{ $params->{campaign} }->{single_opt_in},
        } );
    }

    return 1;
}

sub _mail_newsletter {
    my ( $self, $subscribers, $content ) = @_;
    $content ||= read_text( $self->newsletter_file );

    my ( $subject, $body ) = split "\n", $content, 2;
    $subject =~ s/^Subject: //;
    my $layout = $self->campaigns->{friends}->{layout};

    for my $subscriber( @{ $subscribers } ) {
        $self->email_plaintext(
            'v',
            $subscriber,
            $subject,
            $body,
            $layout
        );
    }

    return $self->smtp->transport;
}

sub queue_newsletter {
    my ( $self, $params ) = @_;
    unlink $self->newsletter_file if -f $self->newsletter_file;
    open my $fh, '>:encoding(UTF-8)', $self->newsletter_file;

    # On the one hand, in-band config and messaging is messy
    # On the other, it is convenient
    printf $fh "Subject: %s\n", $params->{email_subject};
    print $fh $params->{email_body};

    return 'Newsletter queued for delivery. Thank you!';
}

sub send_newsletter {
    my ( $self ) = @_;
    return unless -f $self->newsletter_file;

    $self->_mail_newsletter(
        rset('Subscriber')
            ->campaign('friends')
            ->subscribed
            ->verified
            ->unbounced
            ->all_ref
    );

    unlink $self->newsletter_file;
}

sub test_newsletter {
    my ( $self, $params ) = @_;
    my $email = Email::Valid->address( $params->{test_address} );
    return "Not a duckduckgo email address"
        unless $email =~ /\@duckduckgo\.com$/;

    my $schema = DaxMailer::Schema->connect('dbi:SQLite:dbname=:memory:');
    $schema->deploy;

    my $subscriber = $schema->resultset('Subscriber')->create( {
        email_address => $email,
        campaign      => 'friends',
        verified      => 1,
    } );

    $self->_mail_newsletter(
        [ $subscriber ],
        sprintf "Subject: %s\n%s",
            $params->{email_subject},
            $params->{email_body},
    );

    return 'Test newsletter sent!';
}

1;
