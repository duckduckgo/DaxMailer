package Mailtrain::API;

use Moo;
use URI;
use URI::QueryParam;

has proto => ( is => 'ro', default  => sub { 'https' } );
has port  => ( is => 'ro', default  => sub { 3000 } );
has host  => ( is => 'ro', required => 1 );
has token => ( is => 'ro', required => 1 );
has list  => ( is => 'ro', required => 1 );

has http => ( is => 'lazy' );
sub _build_http {
    require HTTP::Tiny;
    HTTP::Tiny->new;
}

sub _uri {
    my ( $self ) = @_;
    my $uri = URI->new(
        sprintf '%s://%s:%s/',
        $self->proto,
        $self->host,
        $self->port,
    );
    $uri->query_param( access_token => $self->token );
    return $uri;
}

sub subscription {
    my ( $self, $operation, @emails ) = @_;
    my ( @success, @fail );

    my $uri = $self->_uri;
    $uri->path(
        sprintf '/api/%s/%s',
        $operation,
        $self->list,
    );
    $uri = $uri->canonical->as_string;

    for my $email ( @emails ) {
        my $response = $self->http->post_form(
            $uri, { EMAIL => $email }
        );
        if ( $response->{success} ) {
            push @success, $email;
        }
        else {
            push @fail, {
                email => $email,
                reason => $response->{reason},
                content => $response->{content},
            }
        }
    }

    +{
        success => \@success,
        fail    => \@fail,
    }
}

sub unsubscribe {
    my ( $self, @emails ) = @_;
    $self->subscription( 'unsubscribe', @emails );
    $self->subscription( 'delete', @emails );
}

sub subscribe {
    my ( $self, @emails ) = @_;
    $self->subscription( 'subscribe', @emails );
}

1;
