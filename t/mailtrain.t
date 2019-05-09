use strict;
use warnings;

my @subtests = (
    { email => 'invalidemail', news => 1, fail => 1 },
    { email => 'test1@ddg.gg', tips => 1, },
    { email => 'test2@ddg.gg', tips => 1, news => 1 },
    { email => 'test3@ddg.gg', news => 1, },
    { email => 'test3@ddg.gg', news => 1, },
    { email => 'test1@duck.co', news => 1, },
    { email => 'test1@duckduckgo.com', news => 1, tips => 1 },
);

my @unsubtests = ( qw/
    doesnotexist@ddg.gg
    test3@ddg.gg
    test1@duckduckgo.com
    test1@duck.co
    doesnotexist@duck.co
/ );

my @datatests = (
    [ qw/ test2@ddg.gg subscribe 1 / ],
    [ qw/ test3@ddg.gg subscribe 1 / ],
    [ qw/ test1@duck.co subscribe 0 / ],
    [ qw/ test1@duckduckgo.com subscribe 1 / ],
    [ qw/ test3@ddg.gg unsubscribe 1 / ],
    [ qw/ test1@duckduckgo.com unsubscribe 0 / ],
    [ qw/ test1@duck.co unsubscribe 1 / ],
    [ qw/ doesnotexist@duck.co unsubscribe 1 / ],
);

use lib 't/lib';
use Test::More;
use File::Temp qw/ tempfile /;

my $server;

BEGIN {
    require Plack::Test::Server;
    require DaxMailer::TestUtils::Mocktrain;

    $ENV{DAXMAILER_DB_DSN} = 'dbi:SQLite:dbname=:memory:';
    $ENV{MAILTRAIN_HOST} = '127.0.0.1';
    $ENV{MAILTRAIN_LIST} = 'n3w-l1st';
    $ENV{MAILTRAIN_ACCESS_TOKEN} = 'da39a3ee5e6b4b0d3255bfef95601890afd80709';

    $server = Plack::Test::Server->new(
        DaxMailer::TestUtils::Mocktrain->app
    );
    if ( !$server ) {
        plan skip_all => 'Unable to run Mailtrain mock server';
    }

    $ENV{MAILTRAIN_PORT} = $server->port;

}

use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use DaxMailer::TestUtils;
use DaxMailer::Base::Web::Service;
use DaxMailer::Web::App::Subscriber;
use DaxMailer::Script::Mailtrain;

DaxMailer::TestUtils::deploy( { drop => 1 }, schema );

my $app = builder {
    mount '/s' => DaxMailer::Web::App::Subscriber->to_app;
};

test_psgi $app => sub {
    my ( $cb ) = @_;

    my $subcribe = sub {
        my ( $params ) = @_;
        $cb->(
            POST '/s/a', [ %{ $params }, flow  => 'test' ]
        )->is_success;
    };

    my $unsubscribe = sub {
        my ( $email ) = @_;
        $cb->( GET "/s/unsub/news/$email" )->is_success;
    };

    for my $test ( @subtests ) {
        if ( delete $test->{fail} ) {
            ok( ! $subcribe->( $test ), 'Failed to subscribe ' . $test->{email} );
            next;
        }

        ok( $subcribe->( $test ), 'Subscribed ' . $test->{email} );

        ok(
            rset('Subscriber')->find( $test->{email}, 'b' ),
            'Found tips subscriber ' . $test->{email}
        ) if $test->{tips};

        ok(
            rset('Subscriber::Mailtrain')->find( $test->{email}, 'subscribe' ),
            'Found news subscriber ' . $test->{email}
        ) if $test->{news};

    }

    ok( $unsubscribe->( $_ ), "Unsubscribed $_" )
        for @unsubtests;

};

DaxMailer::Script::Mailtrain->new->go;

for my $test ( @datatests ) {
    my ( $email, $operation, $processed ) = @{ $test };
    my $subscriber;
    ok( $subscriber = rset('Subscriber::Mailtrain')->find( $email, $operation ),
        "Found mailtrain queue row for $email" );
    is( $subscriber->processed, 1, "$email processed as expected" );
}

done_testing;
