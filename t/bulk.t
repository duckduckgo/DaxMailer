use strict;
use warnings;

BEGIN {
    use File::Temp qw/ tempfile /;
    $ENV{DAXMAILER_DB_DSN} = 'dbi:SQLite:dbname=:memory:';
    $ENV{DAXMAILER_MAIL_TEST} = 1;
    $ENV{DAXMAILER_BASIC_AUTH_USER}='test';
    $ENV{DAXMAILER_BASIC_AUTH_PASS}='test';
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

DaxMailer::TestUtils::deploy( { drop => 1 }, schema );

my $app = builder {
    mount '/s' => DaxMailer::Web::App::Subscriber->to_app;
};

my $to = <<'TESTMAILS';
test1@duckduckgo.com, test2@duckduckgo.com, foo, bar
invalid.address,test3@duckduckgo.com,  test4@duckduckgo.com,


test5@duckduckgo.com

              test6@duckducko.com,test6@duckducko.com
TESTMAILS

test_psgi $app => sub {
    my ( $cb ) = @_;

    my $req = POST '/s/bulk', [ to => $to, campaign => 'b', flow => 'bulk' ];
    $req->authorization_basic( $ENV{DAXMAILER_BASIC_AUTH_USER}, $ENV{DAXMAILER_BASIC_AUTH_PASS} );

    ok( $cb->( $req )->is_success, "Adding bulk subscribers" );

    is( rset('Subscriber')->count, 6, '6 valid unique emails added' );
};

done_testing;

