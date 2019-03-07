use strict;
use warnings;

BEGIN {
    use File::Spec::Functions;
    $ENV{DAXMAILER_DB_DSN} = 'dbi:SQLite:dbname=:memory:';
    $ENV{DAXMAILER_MAIL_TEST} = 1;
}

use lib 't/lib';
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Test::More;
use DaxMailer::Base::Web::Common;
use DaxMailer::TestUtils;
use DaxMailer::Web::App::Subscriber;

DaxMailer::TestUtils::deploy( { drop => 1 }, schema );

my $app = builder {
    mount '/s' => DaxMailer::Web::App::Subscriber->to_app;
};


test_psgi $app => sub {
    my ( $cb ) = @_;

    my $res = $cb->(
        POST '/s/a',
        [ email => 'test@ddg.gg', campaign => 'a', flow => 'foo', page => 1 ]
    );
    is( $res->code, 302, 'Redirect after POST' );
    like( $res->header( 'Location' ), qr{/s/a$}, 'Redirect location' );

    $res = $cb->( GET '/s/a' );
    is( $res->code, 200, 'GET add endpoint' );
    like( $res->decoded_content, qr{thank\ you}i, 'GET add endpoint' );
};

done_testing;
