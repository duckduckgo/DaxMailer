use strict;
use warnings;

use lib 't/lib';
use Test::More;
use File::Temp qw/ tempfile /;

my $server;

BEGIN {
    require Plack::Test::Server;
    require DaxMailer::TestUtils::Mocktrain;

    $server = Plack::Test::Server->new(
        DaxMailer::TestUtils::Mocktrain->app
    );
    if ( !$server ) {
        plan skip_all => 'Unable to run Mailtrain mock server';
    }

    $ENV{DAXMAILER_DB_DSN} = 'dbi:SQLite:dbname=:memory:';
    $ENV{MAILTRAIN_HOST} = '127.0.0.1';
    $ENV{MAILTRAIN_LIST} = 'n3w-l1st';
    $ENV{MAILTRAIN_PORT} = $server->port;
    $ENV{MAILTRAIN_ACCESS_TOKEN} = 'da39a3ee5e6b4b0d3255bfef95601890afd80709';
}

use Plack::Test;
use Plack::Builder;
use DaxMailer::TestUtils;
use DaxMailer::Base::Web::Service;
use DaxMailer::Web::App::Subscriber;
use DaxMailer::Script::Mailtrain;

DaxMailer::TestUtils::deploy( { drop => 1 }, schema );

my $app = builder {
    mount '/s' => DaxMailer::Web::App::Subscriber->to_app;
};

test_psgi $app => sub {
};

DaxMailer::Script::Mailtrain->new->go;

ok(1, 'ok');

done_testing;
