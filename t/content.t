use strict;
use warnings;

BEGIN {
    $ENV{DAXMAILER_MAIL_TEST} = 1;
}

use Test::More;
use HTML::TreeBuilder::XPath;
use DaxMailer::Script::SubscriberMailer;

sub html_body {
    my ( $email ) = @_;
    my $mime = $email->{email}->cast('Email::MIME');
    my @parts = $mime->subparts;
    return $parts[1]->body_str;
}

sub find_verify_link {
    my ( $email ) = @_;
    my $tree = HTML::TreeBuilder::XPath->new_from_content( html_body( $email ) );
    ( grep { $_->content->[0] eq 'Get More Privacy Tips by Email!' } $tree->findnodes('//a') )[0];
}

sub find_unsub_link {
    my ( $email ) = @_;
    my $tree = HTML::TreeBuilder::XPath->new_from_content( html_body( $email ) );
    ( grep { $_->content->[0] eq 'unsubscribe' } $tree->findnodes('//a') )[0];
}

my $mailer = DaxMailer::Script::SubscriberMailer->new;
my ( $transport, $subscriber ) = $mailer->testrun(
    'c', 'test1@duckduckgo.com',
    { from => 'Simon' }
);
my @emails = $transport->deliveries;
my @subjects = (
    "Private Browsing Myths from Simon",
    "Ads Cost You Money?",
    "Privacy Tip from Simon",
    "Tracking in Incognito?",
    "Are Ads Following You?",
    "Are Ads Costing You Money?",
    "Have You Deleted Your Google Search History Yet?",
    "Is Your Data Being Sold?",
    "Who Decides What Websites You Visit?",
    "Was This Useful?",
);

for my $email (0..9) {
    is( $emails[$email]->{email}->get_header("Subject"),
        $subjects[$email],
        sprintf( "Subject %d", $email + 1 )
    );
    my $node = find_unsub_link( $emails[$email] );
    ok( $node, 'Unsub link found' );
    ok( $node->attr('href') =~ m{/s/u/c/},
        sprintf( "Unsub link destination %d", $email + 1 )
    );
    is( $node->attr('href'), $subscriber->unsubscribe_url,
        sprintf( "Unsub link full content %d", $email + 1 )
    );
}

for my $email (0..2) {
    my $node = find_verify_link( $emails[$email] );
    ok( $node, 'Verify link found' );
    ok( $node->attr('href') =~ m{/s/v/c/},
        sprintf( "Verify link destination %d", $email + 1 )
    );
    is( $node->attr('href'), $subscriber->verify_url,
        sprintf( "Verify link full content %d", $email + 1 )
    );
}

done_testing;
