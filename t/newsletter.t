use strict;
use warnings;

BEGIN {
    use File::Spec::Functions;
    $ENV{DAXMAILER_DB_DSN} = 'dbi:SQLite:dbname=:memory:';
    $ENV{DAXMAILER_MAIL_TEST} = 1;
    $ENV{DAXMAILER_NEWSLETTER_FILE} = catfile( $ENV{HOME}, 'test_newsletter.txt' );
    unlink $ENV{DAXMAILER_NEWSLETTER_FILE};
}


use lib 't/lib';
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Test::More;
use DaxMailer::TestUtils;
use DaxMailer::Web::App::Subscriber;
use DaxMailer::Base::Web::Common;
use DaxMailer::Script::SubscriberMailer;
use URI;
use File::Temp qw/ tempfile /;

DaxMailer::TestUtils::deploy( { drop => 1 }, schema );

my $app = builder {
    mount '/s' => DaxMailer::Web::App::Subscriber->to_app;
};

sub _unsubscribe {
    my ( $cb, $email, $campaign ) = @_;
    my $subscriber = rset('Subscriber')->find( {
        email_address => $email,
        campaign => $campaign,
    } );
    my $url = URI->new( $subscriber->unsubscribe_url );
    ok(
        $cb->( GET $url->path )->is_success,
        "Unsubscribing " . $subscriber->email_address
    );
}

test_psgi $app => sub {
    my ( $cb ) = @_;

    for my $email (qw/
        test1@duckduckgo.com
        test2@duckduckgo.com
        test3@duckduckgo.com
        "local@part@at"@duckduckgo.com
    / ) {
        ok( $cb->(
            POST '/s/a',
            [ email => $email, campaign => 'friends', flow => 'test' ]
        )->is_success, "Adding subscriber : $email" );
    }

    ok( $cb->(
        POST '/s/a',
        [ email => 'notanemailaddress', campaign => 'friends', flow => 'test' ]
    )->is_error, "Adding subscriber : notanemailaddress - failure" );

    is( DaxMailer::Script::SubscriberMailer->new->test_newsletter({
        test_address  => 'test4@duckduckgo.com',
        email_subject => 'Test',
        email_body    => 'Hello',
    }), 'Test newsletter sent!');

    my $file = tempfile;

    is( DaxMailer::Script::SubscriberMailer->new->queue_newsletter({
        email_subject => 'Test',
        email_body    => 'Hello',
    }), 'Newsletter queued for delivery. Thank you!');

    my $transport = DaxMailer::Script::SubscriberMailer->new->send_newsletter;

    is( $transport->delivery_count, 4, 'Mailed newsletter to 4 subscribers' );

    $transport = DaxMailer::Script::SubscriberMailer->new->send_newsletter;

    ok(!$transport, 'No newsletter queued, no mail sent');

    _unsubscribe($cb, '"local@part@at"@duckduckgo.com', 'friends');

    is( DaxMailer::Script::SubscriberMailer->new->queue_newsletter({
        email_subject => 'Test',
        email_body    => 'Hello',
    }), 'Newsletter queued for delivery. Thank you!');

    $transport = DaxMailer::Script::SubscriberMailer->new->send_newsletter;

    is( $transport->delivery_count, 3, 'Mailed newsletter to 3 subscribers' );
};

done_testing;
