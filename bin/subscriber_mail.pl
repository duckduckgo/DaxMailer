#!/usr/bin/env perl

use Moo;
use MooX::Options;

use Test::MockTime qw/ set_absolute_time /;
use FindBin;
use lib $FindBin::Dir . "/../lib";
use DaxMailer::Script::SubscriberMailer;

option newsletter => (
    is => 'ro',
    doc => 'Send newsletter.txt to subscribers'
);

option verify => (
    is => 'ro',
    doc => 'Run verify mail shot'
);

option mock_date => (
    is => 'ro',
    format => 's',
    doc => 'Run mail for given day (for testing): YYYY-MM-DD',
    coerce => sub {
        set_absolute_time(sprintf '%sT12:00:00Z', $_[0]);
    }
);

my $self = main->new_with_options;

if ( $self->mock_date ) {
    printf "Run with mock date [y/N]? ";
    chomp ( my $r = <STDIN> );
    die unless $r =~ /^y/i;
}

if ( $self->verify ) {
    DaxMailer::Script::SubscriberMailer->new->verify;
}
elsif ( $self->newsletter ) {
    DaxMailer::Script::SubscriberMailer->new->send_newsletter;
}
else {
    DaxMailer::Script::SubscriberMailer->new->execute;
}

