use strict;
use warnings;
package DaxMailer::Script::PurgeMailgun;

use Moo;
use HTTP::Request;
use LWP::UserAgent;
use JSON;
use Try::Tiny;
use MIME::Base64;

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
        warn "Calling _purge_mailgun() with uri $uri";
        $self->_purge_mailgun($uri, $api_key);
    }
}

sub _purge_mailgun {
    my ( $self, $api_uri, $api_key ) = @_;

    my @bounces;

    # Get bounces list
    my $encoded_credentials = encode_base64("api:$api_key");
    my $req_bounces = HTTP::Request->new( 'GET', $api_uri, [
              'Authorization' => "Basic $encoded_credentials"
              ] );
    my $ua = LWP::UserAgent->new();
    my $res_bounces;
    my $content;
    my $next_page;
    my $tot_bounces;
    
    try {
        $res_bounces = $ua->request($req_bounces);
        $content = from_json($res_bounces->content());
        @bounces = $content->{items};
        $next_page = $content->{paging} ? $content->{paging}->{next} : '';
    } catch {
        warn "Error trying to fetch data for $api_uri: $_";
    };

    for my $bounces_page ( @bounces ) {
        $tot_bounces = scalar @{$bounces_page};
        for my $bounced ( @{$bounces_page} ) {
            my $address = $bounced->{address};
            warn "Purging email address $address from local DB";

            # Delete from local and Mailtrain DBs
            try {
                rset('Subscriber::Mailtrain')->unsubscribe( $address );
            } catch {
                warn "Couldn't delete $address from Mailtrain: $_";
            };

            try {
                rset('Subscriber')->find( { 
                    email_address => $address,
                    campaign => 'b' 
                } )->delete();
            } catch {
                warn "Couldn't delete $address from DaxMailer: $_";
            };

            # Delete bounced address from Mailgun
            warn "Delete $address from Mailgun";
            my $req_delete = HTTP::Request->new( 'DELETE', "$api_uri/$address", [
                        'Authorization' => "Basic $encoded_credentials"
                      ] );
            my $ua = LWP::UserAgent->new();
            my $res_delete;
            
            try {
                $res_delete = $ua->request($req_delete);
            } catch {
                warn "Error trying to delete $address: $_";
            };
        }
    }

    if ( defined($next_page) and $next_page ne '' and $tot_bounces > 0) {
        warn "Calling _purge_mailgun() with uri $next_page";
        $self->_purge_mailgun($next_page, $api_key);
    }
}

1;
