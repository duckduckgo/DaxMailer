use strict;
use warnings;
package DaxMailer::Script::SubscriberMailer;

use Test::MockTime qw/ set_absolute_time /;
use DateTime;
use Moo;
use MooX::Options;
use String::Truncate qw/ trunc /;
use File::Spec::Functions;
use File::Slurper qw/ read_text /;
use Carp;
use DaxMailer::Util::Strings;
use Try::Tiny;

with 'DaxMailer::Base::Script::Service',
     'DaxMailer::Base::Script::ServiceEmail';

option newsletter => (
    is => 'ro',
    doc => 'Send newsletter.txt to subscribers'
);

option verify => (
    is => 'ro',
    doc => 'Run verify mail shot'
);

option oneoff => (
    is => 'ro',
    format => 's',
    doc => 'Run one-off mail shot'
);

option mock_date => (
    is => 'ro',
    format => 's',
    doc => 'Run mail for given day (for testing): YYYY-MM-DD',
    predicate => 1,
    coerce => sub {
        printf "Run with mock date [y/N]? ";
        chomp ( my $r = <STDIN> );
        die unless $r =~ /^y/i;
        set_absolute_time(sprintf '%sT12:00:00Z', $_[0]);
    }
);

has stringutils => ( is => 'lazy' );
sub _build_stringutils {
    DaxMailer::Util::Strings->new;
}

has newsletter_file => ( is => 'lazy' );
sub _build_newsletter_file {
    return $ENV{DAXMAILER_NEWSLETTER_FILE} if $ENV{DAXMAILER_NEWSLETTER_FILE};
    my $file_store = config()->{file_store};
    croak "No persistent store configured" unless $file_store;
    catfile( $file_store, 'newsletter.txt' );
}

has campaigns => ( is => 'lazy' );
sub _build_campaigns {
    config()->{campaigns};
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

has mailtrain => ( is => 'lazy' );
sub _build_mailtrain {
    require DaxMailer::Script::Mailtrain;
    DaxMailer::Script::Mailtrain->new;
}

sub email {
    my ( $self, $log, $subscriber, $subject, $template, $layout, $verified ) = @_;

    my $status;

    try {
        $status = $self->smtp->send( {
            to       => $subscriber->email_address,
            verified => $verified
                        || ( $subscriber->verified && !$subscriber->unsubscribed ),
            from     => '"DuckDuckGo Dax" <dax@mailer.duckduckgo.com>',
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
    } catch {
        warn $_;
    };

    return $status;

}

sub email_plaintext {
    my ( $self, $log, $subscriber, $subject, $content, $layout, $verified ) = @_;

    my $status = $self->smtp->send_plaintext( {
        to       => $subscriber->email_address,
        verified => $verified
                    || ( $subscriber->verified && !$subscriber->unsubscribed ),
        from     => '"DuckDuckGo Dax" <dax@mailer.duckduckgo.com>',
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

sub send_campaign {
    my ( $self ) = @_;

    for my $campaign ( sort keys %{ $self->campaigns } ) {
        next if !$self->campaigns->{ $campaign }->{live};
        my @mail_map = (
            'v',
            sort { $a <=> $b }
            grep { /^[0-9]+$/ }
            grep { !$self->campaigns->{ $campaign }->{mails}->{ $_ }->{oneoff} }
            keys %{ $self->campaigns->{ $campaign }->{mails} }
        );
        for my $i ( 1..$#mail_map ) {
            my $mail = $mail_map[ $i ];
            my $prev_mail = $mail_map[ $i -1 ];
            my $days = $self->campaigns->{ $campaign }->{mails}->{ $mail }->{days};
            $days -= $self->campaigns->{ $campaign }->{mails}->{ $prev_mail }->{days}
                if $self->campaigns->{ $campaign }->{mails}->{ $prev_mail }->{days};
            my @subscribers = rset('Subscriber')
                ->campaign( $campaign )
                ->subscribed
                ->verified
                ->unbounced
                ->mail_unsent( $campaign, $mail )
                ->mail_sent_days_ago( $campaign, $prev_mail, $days )
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

sub send_verify {
    my ( $self ) = @_;

    for my $campaign ( keys %{ $self->campaigns } ) {
        next if !$self->campaigns->{ $campaign }->{live};
        my @subscribers = rset('Subscriber')
            ->campaign( $campaign )
            ->unverified( $self->campaigns->{ $campaign }->{single_opt_in} )
            ->verification_mail_unsent_for( $campaign )
            ->subscribed
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

    goto MAILRUNS if $extra->{which} && $extra->{which} ne 'v';

    if ( my $tm = $self->campaigns->{ $campaign }->{template_map} ) {
        for my $template ( sort keys %{ $self->template_map->{ $tm } } ) {
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

    goto VERIFYONLY if $extra->{verify_only} || ( $extra->{which} && $extra->{which} eq 'v' );

MAILRUNS:

    my $mails = $self->campaigns->{ $campaign }->{mails};
    for my $mail ( ( sort { $a <=> $b }
                     grep { /^[0-9]+$/ }
                     keys %{ $mails } ), 'extension', 'crowdfunding' ) {
        next if ( $extra->{which} && $extra->{which} ne $mail );
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

    return $self->smtp->transport;
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

sub send_oneoff {
    my ( $self, $email ) = @_;

    my @campaigns = grep {
        $self->campaigns->{ $_ }->{mails}->{ $email } &&
        $self->campaigns->{ $_ }->{mails}->{ $email }->{oneoff} &&
        $self->campaigns->{ $_ }->{live} &&
        ( !$self->campaigns->{ $_ }->{mails}->{ $email }->{expires} ||
          DateTime->now->ymd lt $self->campaigns->{ $_ }->{mails}->{ $email }->{expires} )
    } keys %{ $self->campaigns };

    my @subscribers = map {
        rset('Subscriber')
            ->campaign( $_ )
            ->subscribed
            ->verified
            ->unbounced
            ->mail_unsent( $_, $email )
            ->join_latest_email
            ->all
    } @campaigns;

    for my $subscriber ( @subscribers ) {
        $self->email(
            $email,
            $subscriber,
            $self->campaigns->{ $subscriber->campaign }->{mails}->{ $email }->{subject},
            $self->campaigns->{ $subscriber->campaign }->{mails}->{ $email }->{template},
            $self->campaigns->{ $subscriber->campaign }->{layout},
        );
    }
}

sub go {
    my ( $self ) = @_;
    if ( $self->has_mock_date ) {
        printf "RUNNING WITH MOCK DATE %s\n", DateTime->now->ymd;
    }

    if ( $self->verify ) {
        $self->send_verify;
        $self->mailtrain->go;
    }
    elsif ( $self->newsletter ) {
        $self->send_newsletter;
    }
    elsif ( $self->oneoff ) {
        $self->send_oneoff( $self->oneoff );
    }
    else {
        $self->send_campaign;
    }
}

1;
