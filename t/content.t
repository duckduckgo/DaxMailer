use strict;
use warnings;

BEGIN {
    $ENV{DAXMAILER_MAIL_TEST} = 1;
}

use Test::More;
use DaxMailer::Script::SubscriberMailer;

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
        sprintf( "Test subject %d", $email + 1)
    );
}

done_testing;
