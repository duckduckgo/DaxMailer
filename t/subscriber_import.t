use strict;
use warnings;

BEGIN {
    $ENV{DAXMAILER_DB_DSN} = 'dbi:SQLite:dbname=:memory:';
}

use lib 't/lib';
use Test::More;
use DaxMailer::TestUtils;
use DaxMailer::Base::Web::Common;
use DaxMailer::Script::ImportSubscribers;
use FindBin;
use File::Spec::Functions;

DaxMailer::TestUtils::deploy( { drop => 1 }, schema );

my $bounce_file = catfile( $FindBin::Bin, qw/ var bounce.txt / );
my $emails_file = catfile( $FindBin::Bin, qw/ var emails.txt / );

DaxMailer::Script::ImportSubscribers->new(
    file => $bounce_file,
    list => 'unsub',
)->go;

is( rset('Subscriber::Bounce')->count, 2,
    '2 unique, valid email address unsubscribed' );

DaxMailer::Script::ImportSubscribers->new(
    file => $emails_file,
    list => 'friends',
)->go;

my $subscribers_rs =
    rset('Subscriber')
        ->campaign( 'friends' )
        ->subscribed
        ->verified
        ->unbounced
        ->order_by( 'email_address' );

is( $subscribers_rs->count, 2,
    '2 unique, valid addresses remain subscribed' );

my $subscribers = $subscribers_rs->all_ref;

is( $subscribers->[0]->email_address, 'test1@duckduckgo.com',
    'First subscriber address correct' );

is( $subscribers->[1]->email_address, 'test3@duckduckgo.com',
    'Second subscriber address correct' );

done_testing;
