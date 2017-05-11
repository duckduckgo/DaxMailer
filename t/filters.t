use strict;
use warnings;

BEGIN {
    $ENV{DAXMAILER_DB_DSN} = 'dbi:SQLite:dbname=:memory:';
    $ENV{DAXMAILER_MAIL_TEST} = 1;
}


use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Test::More;
use t::lib::DaxMailer::TestUtils;
use DaxMailer::Web::App::Subscriber;
use DaxMailer::Base::Web::Common;
use DaxMailer::Script::SubscriberMailer;
use URI;

t::lib::DaxMailer::TestUtils::deploy( { drop => 1 }, schema );

my $app = builder {
    mount '/s' => DaxMailer::Web::App::Subscriber->to_app;
};

test_psgi $app => sub {
    my ( $cb ) = @_;

    for my $email (qw/
        test1@duckduckgo.com
        test2@duckduckgo.com
        test3@duckduckgo.com
    / ) {
        ok( $cb->(
            POST '/s/a',
            [ email => $email, campaign => 'a', flow => 'flow1' ]
        )->is_success, "Adding subscriber : $email" );
    }

    is ( rset('Subscriber')->count, 3, "3 subscribers in db" );

    my $_add_subscriber = sub {
        my ( $from, @emails ) = @_;
        ok( $cb->(
            POST '/s/a',
            [ from => $from, to => join( ',', @emails) , campaign => 'c', flow => 'flow1' ]
        )->is_success, "Adding subscriber : $emails[0]" );
    };

    $_add_subscriber->( '有趣的乐趣126.com你好', qw/ foo@duckduckgo.com bar@example.org / );

    is ( rset('Subscriber')->count, 5, "5 subscribers in db" );
    is ( rset('Subscriber')->subscribed->count, 3, "3 non-unsub subscribers in db" );

    $_add_subscriber->( 'Bob', qw/ baz@duckduckgo.com fake1@qq.com / );

    is ( rset('Subscriber')->count, 7, "7 subscribers in db" );
    is ( rset('Subscriber')->subscribed->count, 4, "4 non-unsub subscribers in db" );

    $_add_subscriber->( 'Bob@example.com', qw/ qux@duckduckgo.com fake2@qq.com / );

    is ( rset('Subscriber')->count, 9, "9 subscribers in db" );
    is ( rset('Subscriber')->subscribed->count, 5, "5 non-unsub subscribers in db" );

    $_add_subscriber->( '有趣的乐趣126。com你好', qw/ test98@duckduckgo.com / );
    $_add_subscriber->( '有趣的乐趣126点com你好', qw/ test99@duckduckgo.com / );

    is ( rset('Subscriber')->count, 11, "11 subscribers in db" );
    is ( rset('Subscriber')->subscribed->count, 5, "5 non-unsub subscribers in db" );

    my $transport = DaxMailer::Script::SubscriberMailer->new->send_verify;
    is ( $transport->delivery_count, 5, 'Verify not sent to unsubscribed emails' );
};

done_testing;
