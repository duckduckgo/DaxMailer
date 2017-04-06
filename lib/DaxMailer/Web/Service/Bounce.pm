package DaxMailer::Web::Service::Bounce;

# ABSTRACT: Bounce management

use HTTP::Tiny;
use Try::Tiny;
use AWS::SNS::Verify;
use DaxMailer::Base::Web::Service;

sub verify_subscription {
    my $ok = 1;
    my $res = HTTP::Tiny->new->get( $_[0]->{SubscribeURL} );
    if ( !$res->{success} ) {
        status $res->{status};
        $ok = 0;
    }
    return {
        ok => $ok,
        status => $res->{status},
        message => $res->{reason}
    };
}

sub verify_message {
    my ( $body ) = @_;
    return 1 if !config->{verify_sns};
    try {
        AWS::SNS::Verify->new( body => $body )->verify;
        return 1;
    } catch {
        return 0;
    };
}

post '/handler' => sub {
    my $packet = params('body');
    return { ok => 0, status => 401 }
        if (!verify_message( request->body ) );

    if ( $packet->{Type} eq 'SubscriptionConfirmation' ) {
        return verify_subscription( $packet );
    }
    my $message = decode_json( $packet->{Message} );
    return rset('Subscriber::Bounce')->handle_bounces( $message );
};

get '/check/:email' => sub {
    return { ok => (
        rset('Subscriber::Bounce')->check( route_parameters->{email} )
        ? 0
        : 1
    ) };
};

1;
