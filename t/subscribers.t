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
use URI;

DaxMailer::TestUtils::deploy( { drop => 1 }, schema );
my $TEST_LEGACY = DaxMailer::TestUtils::deploy_legacy;

my $app = builder {
    mount '/s' => DaxMailer::Web::App::Subscriber->to_app;
};

sub _verify {
    my ( $cb, $email, $campaign ) = @_;
    my $subscriber = rset('Subscriber')->find( {
        email_address => $email,
        campaign => $campaign,
    } );
    my $url = URI->new( $subscriber->verify_url );
    ok(
        $cb->( GET $url->path )->is_success,
        "Verifying " . $subscriber->email_address
    );
}

sub _unsubscribe {
    my ( $cb, $email, $campaign ) = @_;
    my $subscriber = rset('Subscriber')->find( {
        email_address => $email,
        campaign => $campaign,
    } );
    my $url = URI->new( $subscriber->unsubscribe_url );
    ok(
        $cb->( GET $url->path )->is_success,
        "Unsubscribing " . $subscriber->email_address
    );
}

test_psgi $app => sub {
    my ( $cb ) = @_;

    set_absolute_time('2016-10-18T12:00:00Z');

    for my $email (qw/
        test1@duckduckgo.com
        test2@duckduckgo.com
        test3@duckduckgo.com
    / ) {
        ok( $cb->(
            POST '/s/a',
            [ email => $email, campaign => 'b', flow => 'flow1' ]
        )->is_success, "Adding subscriber : $email" );
    }

    for my $email (qw/
        test4@duckduckgo.com
        test5@duckduckgo.com
        test6@duckduckgo.com
    / ) {
        ok( $cb->(
            POST '/s/a',
            [ email => $email, campaign => 'a', flow => 'flow1' ]
        )->is_success, "Adding subscriber : $email" );
    }

    ok( $cb->(
        POST '/s/a',
        [ email => 'notanemailaddress', campaign => 'a', flow => 'flow1' ]
    )->is_error, "Adding subscriber : notanemailaddress - failure" );

    for my $email (qw/
        test6@duckduckgo.com
        test7@duckduckgo.com
        test8@duckduckgo.com
        test9@duckduckgo.com
        lateverify@duckduckgo.com
    / ) {
        ok( $cb->(
            POST '/s/a',
            [ email => $email, campaign => 'c', flow => 'flow1' ]
        )->is_success, "Adding subscriber : $email" );
    }

    my $invalid = rset('Subscriber')->find( {
        email_address => 'notanemailaddress',
        campaign => 'a'
    } );
    is( $invalid, undef, 'Invalid address not inserted via POST' );

    ok( $cb->(
        POST '/s/a',
        [ email => 'test10@duckduckgo.com', campaign => 'friends', flow => 'flow1' ]
    )->is_success, "Adding newsletter subscriber" );

    my $transport = DaxMailer::Script::SubscriberMailer->new->send_verify;
    is( $transport->delivery_count, 10, 'Correct number of verification emails sent' );

    $transport = DaxMailer::Script::SubscriberMailer->new->send_verify;
    is( $transport->delivery_count, 0, 'No verification emails re-sent' );

    _verify($cb, 'test8@duckduckgo.com', 'c');
    _verify($cb, 'test9@duckduckgo.com', 'c');

    set_absolute_time('2016-10-20T12:00:00Z');
    $transport = DaxMailer::Script::SubscriberMailer->new->send_campaign;
    is( $transport->delivery_count, 8, '8 received emails' );

    $transport = DaxMailer::Script::SubscriberMailer->new->send_campaign;
    is( $transport->delivery_count, 0, 'Emails not re-sent' );

    set_absolute_time('2016-10-21T12:00:00Z');
    $transport = DaxMailer::Script::SubscriberMailer->new->send_campaign;
    is( $transport->delivery_count, 2, '2 received - campaign c mail 2' );

    _unsubscribe($cb, 'test2@duckduckgo.com', 'b');
    _verify($cb, 'lateverify@duckduckgo.com', 'c');

    set_absolute_time('2016-10-22T12:00:00Z');
    $transport = DaxMailer::Script::SubscriberMailer->new->send_campaign;
    is( $transport->delivery_count, 6, '6 received emails - one unsubscribed, one verified' );

    $transport = DaxMailer::Script::SubscriberMailer->new->send_campaign;
    is( $transport->delivery_count, 0, 'Emails not re-sent' );

    set_absolute_time('2016-10-23T12:00:00Z');
    $transport = DaxMailer::Script::SubscriberMailer->new->send_campaign;
    is( $transport->delivery_count, 3, '3 received emails - late verify, rescheduled' );

    $transport = DaxMailer::Script::SubscriberMailer->new->send_campaign;
    is( $transport->delivery_count, 0, 'Emails not re-sent' );

    set_absolute_time('2017-03-31T12:00:00Z');

    rset('Subscriber')->delete;

    ok( $cb->(
        POST '/s/a',
        [   from => 'Your good pal',
            campaign => 'c',
            flow => 'flow1',
            to => join ',', (
                qw{
                    test100@duckduckgo.com
                    test101@duckduckgo.com
                    test102@duckduckgo.com
                    test103@duckduckgo.com
                    test104@duckduckgo.com
                    test105@duckduckgo.com
                    notanemailagain
                }
            )
        ]
    ), "POSTing multiple subscribers" );

    $transport = DaxMailer::Script::SubscriberMailer->new->send_verify;
    is( $transport->delivery_count, 6, 'Correct number of verification emails sent from spread form' );

    _verify($cb, 'test100@duckduckgo.com', 'c');
    _verify($cb, 'test101@duckduckgo.com', 'c');

    set_absolute_time('2017-04-01T12:00:00Z');
    DaxMailer::Script::SubscriberMailer->new->send_campaign;
    _verify($cb, 'test102@duckduckgo.com', 'c');

    set_absolute_time('2017-04-02T12:00:00Z');
    $transport = DaxMailer::Script::SubscriberMailer->new->send_campaign;
    is( $transport->delivery_count, 3, '3 received emails' );

    my @emails = $transport->deliveries;
    is( $emails[0]->{email}->get_header("Subject"),
        'Tracking in Incognito?',
        'Testing first spread email to test102' );

    is( $emails[1]->{email}->get_header("Subject"),
        'Are Ads Following You?',
        'Testing second spread email to test100' );

    is( $emails[2]->{email}->get_header("Subject"),
        'Are Ads Following You?',
        'Testing second spread email to test101' );

    subtest 'legacy unsubs' => sub {
        plan skip_all => 'No legacy db configured'
            unless $TEST_LEGACY;

        ok DaxMailer::TestUtils::add_legacy_subscriber( 'test99@duckduckgo.com', 'a' );
        is( DaxMailer::TestUtils::subscriber_unsubscribed( 'test99@duckduckgo.com', 'a' ), 0,
            'Legacy subscriber test99@duckduckgo.com has unsub flag unset'
        );
        ok(
            $cb->( GET '/s/u/a/test99%40duckduckgo.com/asdf' )->is_success,
            'Legacy unsub GET'
        );
        is( DaxMailer::TestUtils::subscriber_unsubscribed( 'test99@duckduckgo.com', 'a' ), 1,
            'Legacy subscriber test99@duckduckgo.com has unsub flag set'
        );

        done_testing;
    };

};

done_testing;
