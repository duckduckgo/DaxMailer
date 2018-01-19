use strict;
use warnings;

BEGIN {
    use File::Temp qw/ tempfile /;
    $ENV{DAXMAILER_DB_DSN} = 'dbi:SQLite:dbname=:memory:';
    $ENV{LEGACY_DB_DSN} = sprintf 'dbi:SQLite:dbname=%s', (tempfile)[1];
    $ENV{DAXMAILER_SNS_VERIFY_TEST} = 1;
    $ENV{DAXMAILER_MAIL_TEST} = 1;
}

use lib 't/lib';
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Test::More;
use DaxMailer::TestUtils;
use DaxMailer::Web::App::Subscriber;
use DaxMailer::Web::Service::Bounce;
use DaxMailer::Base::Web::Service;

DaxMailer::TestUtils::deploy( { drop => 1 }, schema );

my $app = builder {
    mount '/s' => builder {
        enable "Throttle::Lite",
          limits => '3 req/hour', backend => 'FastMmap',
          routes => [ qr{^/a} ];
        DaxMailer::Web::App::Subscriber->to_app;
    };
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

    for my $email (qw/
        test4@duckduckgo.com
        test5@duckduckgo.com
        test6@duckduckgo.com
    / ) {
        ok( ! $cb->(
            POST '/s/a',
            [ email => $email, campaign => 'a', flow => 'flow1' ]
        )->is_success, "Failing to add subscriber : $email" );
    }

    is( rset('Subscriber')->count, 3, 'Stopped processing adds after 3 requests');

};

done_testing;
