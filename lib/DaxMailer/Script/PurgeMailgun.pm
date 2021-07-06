use strict;
use warnings;
package DaxMailer::Script::PurgeMailgun;

use Moo;
use HTTP::Request;
use LWP::UserAgent;
use JSON;
use Try::Tiny;

with 'DaxMailer::Base::Script::Service';

sub go {
    my ( $self ) = @_;
    
    my $api_domain = $ENV{DAXMAILER_MAILGUN_API_DOMAIN};
    my $api_key = $ENV{DAXMAILER_MAILGUN_API_KEY};
    my $base_uri = "https://api.mailgun.net/v3/$api_domain";
    my @api_uris = (
        "$base_uri/bounces",
        "$base_uri/complaints",
        "$base_uri/unsubscribes"
    );

    for my $uri ( @api_uris ) {
        print "Calling _purge_mailgun() with uri $uri";
        $self->_purge_mailgun($uri, $api_key);
    }
}

sub _purge_mailgun {
    my ( $self, $api_uri, $api_key ) = @_;

    my @bounces = [];

    # Get bounces list
    my $req_bounces = HTTP::Request->new( 'GET', $api_uri, [
              'WWW-Authenticate' => "api:$api_key"
              ] );
    my $ua = LWP::UserAgent->new();
    my $res_bounces;
    
    try {
        $res_bounces = $ua->request($req_bounces);
        push(@bounces, from_json($res_bounces)->items);
    } catch {
        warn "Error trying to fetch data for $api_uri: $_";
    };

    for my $bounced ( @bounces ) {
        my $address = $bounced->address;
        print "Purging email address $address from local DB";

        # Delete from local and Mailtrain DBs
        rset('Subscriber::Mailtrain')->unsubscribe( $address );
        rset('Subscriber')->find( { 
            email_address => $address,
            campaign => 'b' 
        } )->delete();

        # Delete bounced address from Mailgun
        #print "Delete $address from Mailgun";
        #my $req_delete = HTTP::Request->new( 'DELETE', "$api_uri/$address", [
        #          'WWW-Authenticate' => "api:$api_key"
        #          ] );
        #my $ua = LWP::UserAgent->new();
        #my $res_delete;
        #
        #try {
        #    $res_delete = $ua->request($req_delete);
        #} catch {
        #    warn "Error trying to delete $address: $_";
        #};
    }

}

1;
