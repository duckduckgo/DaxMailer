use strict;
use warnings;
package DaxMailer::TestUtils::Mocktrain;

use URI;
use URI::QueryParam;
use Plack::Request;

sub ok { [ 200, [], [ 'OK' ] ] }
sub fail {
    my ( $code, $msg ) = @_;
    [ $code, [], [ $msg ] ];
}
my $app;
sub app { $app }

$app = sub {
    my $env = shift;
    my $req = Plack::Request->new($env);
    my $uri = URI->new( $env->{REQUEST_URI} );
    my $email = $req->body_parameters->{EMAIL};

    return fail( 401, 'Authentication failure' )
        if $ENV{MAILTRAIN_ACCESS_TOKEN} ne $uri->query_param('access_token');

    my ( $operation, $list ) = $uri->path =~ m{/api/([^/]+)/([^/]+)};

    return fail( 500, "Unknown operation $operation" )
        if ( $operation ne 'subscribe' && $operation ne 'unsubscribe' );

    return fail( 500, "Invalid list $list" )
        if $ENV{MAILTRAIN_LIST} ne $list;

    # Arbitrary failure rules

    return fail( 403, 'duck users may not subscribe' )
        if ( $operation eq 'subscribe' && $email =~ /\@duck.co$/ );

    return fail( 403, 'ddg users may not unsubscribe' )
        if ( $operation eq 'unsubscribe' && $email =~ /\@duckduckgo.com$/ );

    return ok;
}
