use strict;
use warnings;

BEGIN {
    use File::Temp qw/ tempfile /;
    $ENV{DAXMAILER_DB_DSN} = 'dbi:SQLite:dbname=:memory:';
    $ENV{DAXMAILER_MAIL_TEST} = 1;
    $ENV{LEGACY_DB_DSN} = sprintf 'dbi:SQLite:dbname=%s', (tempfile)[1];
}


use lib 't/lib';
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Test::More;
use Test::MockTime qw/:all/;
use DaxMailer::TestUtils;
use DaxMailer::Web::App::Subscriber;
use DaxMailer::Base::Web::Common;
use DaxMailer::Script::SubscriberMailer;
use HTML::TreeBuilder::XPath;
use DateTime;
use URI;

DaxMailer::TestUtils::deploy( { drop => 2 }, schema );

my $app = builder {
    mount '/s' => DaxMailer::Web::App::Subscriber->to_app;
};

sub subscriber {
    my ( $email, $campaign ) = @_;
    rset('Subscriber')->find( {
        email_address => $email,
        campaign => $campaign
    } );
}

sub opening_para {
    my ( $email ) = @_;
    my $mime = $email->{email}->cast('Email::MIME');
    my @parts = $mime->subparts;
    my $tree = HTML::TreeBuilder::XPath->new_from_content( $parts[1]->body_str );
    ( $tree->findnodes_as_strings('//p') )[0];
}

test_psgi $app => sub {
    my ( $cb ) = @_;

    my $today = DateTime->now;
    my $s = DaxMailer::Script::SubscriberMailer->new;

    my $add = sub {
        my ( $email, $campaign ) = @_;
        ok( $cb->(
            POST '/s/a',
            [ email => $email, campaign => $campaign, flow => 'flow1' ]
        )->is_success, "Adding subscriber $email" );
    };

    $add->(qw/ testsub1@ddg.gg a /);
    my $transport = $s->send_verify;
    is( $transport->delivery_count, 1, 'Sent verify' );

    for (1..50) {
        $today->add( days => 1 );
        set_absolute_time( $today->iso8601 );
        $s->send_campaign;
    }

    $add->( qw/ testsub2@ddg.gg b / );
    subscriber( qw/ testsub2@ddg.gg b / )->update({ unsubscribed => 1 });
    $add->( qw/ testsub3@ddg.gg c / );

    $transport = $s->send_verify;
    is( $transport->delivery_count, 12, 'Sent verify' );

    subscriber( qw/ testsub3@ddg.gg c / )->update({ verified => 1 });

    for (1..60) {
        $today->add( days => 1 );
        set_absolute_time( $today->iso8601 );
        $s->send_campaign;
    }

    is( $transport->delivery_count, 34, 'Finished one run, halfway through another' );

    $s->send_oneoff('extension');

    is( $transport->delivery_count, 34, 'Not sending expired oneoff' );


    set_absolute_time('2018-01-23T12:00:00Z');

    $s->send_oneoff('extension');
    $s->send_oneoff('extension');

    is( $transport->delivery_count, 36, 'Sent oneoff only once' );

    # Get last two emails delivered
    my @deliveries = ( $transport->deliveries )[-2..-1];

    my $p1 = opening_para( $deliveries[0] );
    my $p2 = opening_para( $deliveries[1] );

    isnt( $p1, $p2, 'Opening paragraph different for mid-run subscriber' );
};


done_testing;
