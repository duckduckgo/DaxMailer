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

    $self->_delete_bounces($api_domain, $api_key);
    # $self->_delete_complaints($api_domain, $api_key); 
}

sub _delete_bounces {
    my ( $self, $api_domain, $api_key ) = @_;

    my @bounces = [];

    # Get bounces list
    my $req_bounces = HTTP::Request->new( 'GET', "https://api.mailgun.net/v3/$api_domain/bounces", [
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
    my $req_delete = HTTP::Request->new( 'DELETE', "https://api.mailgun.net/v3/$api_domain/bounces", [
              'WWW-Authenticate' => "api:$api_key"
              ] );
    my $ua = LWP::UserAgent->new();
    my $res_delete = $ua->request($req_delete);
}

1;
