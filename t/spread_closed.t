use strict;
use warnings;

BEGIN {
    $ENV{DAXMAILER_DB_DSN} = 'dbi:SQLite:dbname=:memory:';
}

use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Test::More;
use t::lib::DaxMailer::TestUtils;
use DaxMailer::Web::App::Subscriber;
use DaxMailer::Base::Web::Common;

t::lib::DaxMailer::TestUtils::deploy( { drop => 1 }, schema );

my $app = builder {
    mount '/s' => DaxMailer::Web::App::Subscriber->to_app;
};

test_psgi $app => sub {
    my ( $cb ) = @_;

    ok( $cb->( POST '/s/a', [ email => 'test998@ddg.gg', campaign => 'b', flow => 'flow1' ] )
        ->is_success,
        "Adding b subscriber"
    );
    ok( $cb->( POST '/s/a', [ email => 'test999@ddg.gg', campaign => 'c', flow => 'flow1' ] )
        ->is_success,
        "Adding c subscriber"
    );
    is( rset('Subscriber')->count, 1, 'c subscriber silently dropped' );
};
done_testing;
