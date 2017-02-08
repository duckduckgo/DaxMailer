use strict;
use warnings;

BEGIN {
    $ENV{DaxMailer_DB_DSN} = 'dbi:SQLite:dbname=daxmailer_test.db';
    $ENV{DaxMailer_MAIL_TEST} = 1;
}


use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Test::More;
use Test::MockTime qw/:all/;
use t::lib::DaxMailer::TestUtils;
use DaxMailer::Web::App::Subscriber;
use DaxMailer::Base::Web::Light;
use DaxMailer::Script::SubscriberMailer;
use URI;

t::lib::DaxMailer::TestUtils::deploy( { drop => 1 }, schema );
my $m = DaxMailer::Script::SubscriberMailer->new;

my $app = builder {
    mount '/s' => DaxMailer::Web::App::Subscriber->to_app;
};

test_psgi $app => sub {
    my ( $cb ) = @_;

    set_absolute_time('2016-10-18T12:00:00Z');

    for my $email (qw/
        test1@duckduckgo.com
        test2@duckduckgo.com
        test3@duckduckgo.com
        test4@duckduckgo.com
        test5@duckduckgo.com
        test6duckduckgo.com
        lateverify@duckduckgo.com
        notanemailaddress
    / ) {
        ok( $cb->(
            POST '/s/a',
            [ email => $email, campaign => 'a', flow => 'flow1' ]
        ), "Adding subscriber : $email" );
    }

    my $invalid = rset('Subscriber')->find( {
        email_address => 'notanemailaddress',
        campaign => 'a'
    } );
    is( $invalid, undef, 'Invalid address not inserted via POST' );

    my $transport = DaxMailer::Script::SubscriberMailer->new->verify;
    is( $transport->delivery_count, 6, 'Correct number of verification emails sent' );

    $transport = DaxMailer::Script::SubscriberMailer->new->verify;
    is( $transport->delivery_count, 0, 'No verification emails re-sent' );

    my $unsubscribe = sub {
        my ( $email ) = @_;
        my $subscriber = rset('Subscriber')->find( {
            email_address => $email,
            campaign => 'a',
        } );
        my $url = URI->new( $subscriber->unsubscribe_url );
        ok(
            $cb->( GET $url->path ),
            "Verifying " . $subscriber->email_address
        );
    };

    my $verify = sub {
        my ( $email ) = @_;
        my $subscriber = rset('Subscriber')->find( {
            email_address => $email,
            campaign => 'a',
        } );
        my $url = URI->new( $subscriber->verify_url );
        ok(
            $cb->( GET $url->path ),
            "Verifying " . $subscriber->email_address
        );
    };

    set_absolute_time('2016-10-20T12:00:00Z');
    $transport = DaxMailer::Script::SubscriberMailer->new->execute;
    is( $transport->delivery_count, 6, '6 received emails' );

    $transport = DaxMailer::Script::SubscriberMailer->new->execute;
    is( $transport->delivery_count, 0, 'Emails not re-sent' );

    set_absolute_time('2016-10-21T12:00:00Z');
    $transport = DaxMailer::Script::SubscriberMailer->new->execute;
    is( $transport->delivery_count, 0, '0 received emails - non scheduled' );

    $unsubscribe->('test2@duckduckgo.com');

    set_absolute_time('2016-10-22T12:00:00Z');
    $transport = DaxMailer::Script::SubscriberMailer->new->execute;
    is( $transport->delivery_count, 5, '5 received emails - one unsubscribed' );

    $transport = DaxMailer::Script::SubscriberMailer->new->execute;
    is( $transport->delivery_count, 0, 'Emails not re-sent' );
};

done_testing;
