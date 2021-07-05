use strict;
use warnings;
package DaxMailer::Script::PurgeMailgun;

use Moo;
use HTTP::Request;
use LWP::UserAgent;
use JSON;

with 'DaxMailer::Base::Script::Service';

sub go {
    my ( $self ) = @_;
    
    my $api_domain = $ENV{DAXMAILER_MAILGUN_API_DOMAIN};
    my $api_key = $ENV{DAXMAILER_MAILGUN_API_KEY};
    my $base_uri = "https://api.mailgun.net/v3/$api_domain";
    my $api_uris = [
        "$base_uri/bounces";
        "$base_uri/complaints";
        "$base_uri/unsubscribes";
    ]

    for my $uri in ( @api_uris ) {
        $self->_purge_mailgun(uri, $api_key);
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
    my $res_bounces = $ua->request($req_bounces);

    push(@bounces, from_json($res_bounces)->items);

    for my $bounced ( @bounces ) {
        my $address = $bounced->address;

        # Delete from local and Mailtrain DBs
        rset('Subscriber::Mailtrain')->unsubscribe( $address );
        rset('Subscriber')->find( { 
            email_address => $address,
            campaign => 'b' 
        } )->delete();
    }

    # Delete bounce list from Mailgun
    my $req_delete = HTTP::Request->new( 'DELETE', $api_uri, [
              'WWW-Authenticate' => "api:$api_key"
              ] );
    my $ua = LWP::UserAgent->new();
    my $res_delete = $ua->request($req_delete);
}

1;
