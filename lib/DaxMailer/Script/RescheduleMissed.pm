use strict;
use warnings;
package DaxMailer::Script::RescheduleMissed;

# Abstract: Shift mail schedule if some days are missed

use DateTime;
use DaxMailer::Script::SubscriberMailer;

use Moo;
use MooX::Options;
with 'DaxMailer::Base::Script::Service';

has now => ( is => 'lazy' );
sub _build_now {
    DateTime->now;
}

has then => ( is => 'lazy' );
sub _build_then {
    DateTime->now->subtract( weeks => 4 );
}

has campaigns => ( is => 'lazy' );
sub _build_campaigns {
    DaxMailer::Script::SubscriberMailer->new->campaigns;
}

has first_mail => ( is => 'lazy' );
sub _build_first_mail {
    my ( $self ) = @_;
    +{
        map {
            $_ => ( sort keys %{ $self->campaigns->{ $_ }->{mails} } )[0]
        } keys %{ $self->campaigns }
    };
}

sub format_date {
    my $schema = schema('default');
    $schema->format_datetime( $_[1] );
}

sub days_ago {
    my ( $self, $days ) = @_;
    $self->format_date(
        DateTime->now->subtract( days => $days )
    );
}

sub subscribers {
    my ( $self ) = @_;
    rset('Subscriber')
        ->search({ created => { '>=' => $self->then->ymd  } })
        ->verified
        ->subscribed;
}

sub maillog_subquery {
    my ( $self, $email_id ) = @_;
    rset('Subscriber::MailLog')
        ->search({
            sent => { '>=' => $self->then->ymd },
            email_id => $email_id,
        })
        ->get_column('email_address')
        ->as_query;
}

sub go {
    my ( $self ) = @_;

    for my $email ( reverse 2..7 ) {
        $self->subscribers->search({
            email_address => { not_in => $self->maillog_subquery( $email ) }
        })->update({
            created => $self->days_ago(
                $self->campaigns->{a}->{mails}->{ $email }->{days}
            )
        });
    }

    $self->subscribers->search({
        campaign => 'c',
        email_address => { not_in => $self->maillog_subquery( 1 ) }
    })->update({ created => $self->days_ago( 1 ) });

    $self->subscribers->search({
        email_address => { not_in => $self->maillog_subquery( 'v' ) }
    })->update({ created => $self->format_date( $self->now ) });

}

1;
