use strict;
use warnings;
package DaxMailer::Script::ImportSubscribers;

use Moo;
use MooX::Options;
use DaxMailer::Script::SubscriberMailer;
use List::Util qw/ uniq /;

with 'DaxMailer::Base::Script::Service';

option file => (
    is       => 'ro',
    required => 1,
    format   => 's',
    doc      => 'Subscriber file to process',
);

option list => (
    is       => 'ro',
    required => 1,
    format   => 's',
    doc      => 'List to add subscribers to. Set this to \'unsub\' to unsubscribe them',
);

sub _filtered_list {
    my ( $self ) = @_;
    open my $fh, '<:encoding(UTF-8)', $self->file
        or die sprintf("Unable to open file %s : %s", $self->file, $!);
    +[
        map  { lc }
        grep { $_ }
        map  { my $v = Email::Valid->address( $_ ) ; $v }
        uniq <$fh>
    ];
}

sub _unsub {
    my ( $self, $list ) = @_;
    rset('Subscriber::Bounce')->update_or_create({
        email_address => lc $_,
        unsubscribed  => 1,
    }) for @{ $list };
}

sub _subscribe {
    my ( $self, $list ) = @_;
    rset('Subscriber')->add_from_post({
        email    => $_,
        campaign => $self->list,
        flow     => 'import'
    }) for @{$list};
}

sub go {
    my ( $self ) = @_;
    return $self->_unsub( $self->_filtered_list ) if lc( $self->list ) eq 'unsub';
    $self->_subscribe( $self->_filtered_list );
}

1;
