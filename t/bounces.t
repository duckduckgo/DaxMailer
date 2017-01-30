use strict;
use warnings;

BEGIN {
    $ENV{DaxMailer_DB_DSN} = 'dbi:SQLite:dbname=daxmailer_test.db';
    $ENV{DaxMailer_SNS_VERIFY_TEST} = 1;
    $ENV{DaxMailer_MAIL_TEST} = 1;
}

use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Test::More;
use t::lib::DaxMailer::TestUtils;
use aliased 't::lib::DaxMailer::TestUtils::AWS' => 'sns';
use DaxMailer::Web::App::Subscriber;
use DaxMailer::Web::Service::Bounce;
use DaxMailer::Base::Web::LightService;

t::lib::DaxMailer::TestUtils::deploy( { drop => 1 }, schema );

my $app = builder {
    mount '/s' => DaxMailer::Web::App::Subscriber->to_app;
    mount '/bounce' => DaxMailer::Web::Service::Bounce->to_app;
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
        ), "Adding subscriber : $email" );
    }

    is( rset('Subscriber')->unbounced->count, 3,
        'No bounce reports received - 3 subscribers' );

    ok( $cb->( POST '/bounce/handler',
            'Content-Type' => 'application/json',
            Content => sns->sns_complaint( 'test1@duckduckgo.com' )
        )->is_success, 'Complaint from test1@duckduckgo.com' );

    is( rset('Subscriber')->unbounced->count, 2,
        'Complaint report received - 2 subscribers remain' );

    ok( $cb->( POST '/bounce/handler',
            'Content-Type' => 'application/json',
            Content => sns->sns_transient_bounce( 'test2@duckduckgo.com' )
        )->is_success, 'Transient bounce message about test2@duckduckgo.com' );

    is( rset('Subscriber')->unbounced->count, 2,
        'Transient bounce received - 2 subscribers remain' );

    ok( $cb->( POST '/bounce/handler',
            'Content-Type' => 'application/json',
            Content => sns->sns_permanent_bounce( 'test3@duckduckgo.com' )
        )->is_success, 'Permanent bounce message about test3@duckduckgo.com' );

    is( rset('Subscriber')->unbounced->count, 1,
        'Permanent bounce received - 1 subscriber remains' );

};

done_testing;
