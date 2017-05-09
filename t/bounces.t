use strict;
use warnings;

BEGIN {
    use File::Temp qw/ tempfile /;
    $ENV{DAXMAILER_DB_DSN} = 'dbi:SQLite:dbname=:memory:';
    $ENV{LEGACY_DB_DSN} = sprintf 'dbi:SQLite:dbname=%s', (tempfile)[1];
    $ENV{DAXMAILER_SNS_VERIFY_TEST} = 1;
    $ENV{DAXMAILER_MAIL_TEST} = 1;
}

use Encode;
use charnames ':full';
use open ':std', ':encoding(UTF-8)';

use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Test::More;
use t::lib::DaxMailer::TestUtils;
use aliased 't::lib::DaxMailer::TestUtils::AWS' => 'sns';
use DaxMailer::Web::App::Subscriber;
use DaxMailer::Web::Service::Bounce;
use DaxMailer::Base::Web::Service;

t::lib::DaxMailer::TestUtils::deploy( { drop => 1 }, schema );
my $TEST_LEGACY = t::lib::DaxMailer::TestUtils::deploy_legacy;

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
            Content => sns->sns_permanent_bounce( encode( 'UTF-8', "test\N{OHM SIGN}\@duckduckgo.com" ) )
        )->is_success, "Permanent bounce message about test\N{OHM SIGN}\@duckduckgo.com" );

    ok( $cb->( POST '/bounce/handler',
            'Content-Type' => 'application/json',
            Content => sns->sns_permanent_bounce( 'test3@duckduckgo.com' )
        )->is_success, 'Permanent bounce message about test3@duckduckgo.com' );

    ok( $cb->( POST '/bounce/handler',
            'Content-Type' => 'application/json',
            Content => sns->sns_permanent_bounce( 'nonexistentguy@example.com' )
        )->is_success, 'Permanent bounce message about nonexistentguy@example.com, a non-subscriber' );

    is( rset('Subscriber')->unbounced->count, 1,
        'Permanent bounce received - 1 subscriber remains' );

    my $check = $cb->( GET '/bounce/check/nonexistentguy%40example.com' );
    ok( $check->is_success, 'Retrieved bounce check report for nonexistentguy@example.com' );
    my $check_result = decode_json( $check->decoded_content );
    is( $check_result->{ok}, 0, 'Check for nonexistentguy@example.com returns not OK' );


    $check = $cb->( GET '/bounce/check/existentguy%40example.com' );
    ok( $check->is_success, 'Retrieved bounce check report for existentguy@example.com' );
    $check_result = decode_json( $check->decoded_content );
    is( $check_result->{ok}, 1, 'Check for existentguy@example.com returns OK' );

    subtest 'legacy bounces' => sub {
        plan skip_all => 'No legacy db configured'
            unless $TEST_LEGACY;

        ok t::lib::DaxMailer::TestUtils::add_legacy_subscriber( 'test99@duckduckgo.com', 'a' );
        is( t::lib::DaxMailer::TestUtils::subscriber_bounced( 'test99@duckduckgo.com', 'a' ), 0,
            'Legacy subscriber test99@duckduckgo.com has bounce flag unset'
        );
        ok( $cb->( POST '/bounce/handler',
            'Content-Type' => 'application/json',
            Content => sns->sns_permanent_bounce( 'test99@duckduckgo.com' )
        )->is_success, 'test99@duckduckgo.com' );
        is( t::lib::DaxMailer::TestUtils::subscriber_bounced( 'test99@duckduckgo.com', 'a' ), 1,
            'Legacy subscriber test99@duckduckgo.com has bounce flag set'
        );

        ok t::lib::DaxMailer::TestUtils::add_legacy_subscriber( 'test99@duckduckgo.com', 'a' );
        is( t::lib::DaxMailer::TestUtils::subscriber_complaint( 'test99@duckduckgo.com', 'a' ), 0,
            'Legacy subscriber test99@duckduckgo.com has complaint flag unset'
        );
        ok( $cb->( POST '/bounce/handler',
            'Content-Type' => 'application/json',
            Content => sns->sns_complaint( 'test99@duckduckgo.com' )
        )->is_success, 'test99@duckduckgo.com' );
        is( t::lib::DaxMailer::TestUtils::subscriber_complaint( 'test99@duckduckgo.com', 'a' ), 1,
            'Legacy subscriber test99@duckduckgo.com has complaint flag set'
        );

        done_testing;
    }
};

done_testing;
