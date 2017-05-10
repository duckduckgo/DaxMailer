use strict;
use warnings;
package DaxMailer::Util::Strings;

# ABSTRACT: String, url and email address processing utils

use Domain::PublicSuffix;
use Email::Address;
use HTTP::Tiny;

use Moo;

with qw/ DaxMailer::Base::Script::Service /;

has http => ( is => 'lazy' );
sub _build_http {
    HTTP::Tiny->new;
}

has publicsuffix => ( is => 'lazy' );
sub _build_publicsuffix {
    my ( $self ) = @_;
    if ( -f config()->{effective_tld_names} ) {
        my $response = $self->http->mirror(
            config()->{effective_tld_names_url},
            config()->{effective_tld_names}
        );
        return unless $response->{success};
    }
    Domain::PublicSuffix->new({
        data_file => config()->{effective_tld_names}
    });
}

sub extract_non_email_domain_like_strings {
    my ( $self, $string ) = @_;
    [
        grep { $_ !~ /^@/ }
            $string =~
            /(?:https?\:\/\/)?(@?[a-z0-9-_]+\.[a-z0-9-_.]+)/ig
    ];
}

sub looks_like_contains_real_domains {
    my ( $self, $string ) = @_;
    return warn "Skipping domain check!!" if !$self->publicsuffix;
    my $urls = $self->extract_non_email_domain_like_strings( $string );
    return !!grep { $self->publicsuffix->get_root_domain( $_ ) } @{ $urls };
}

sub extract_domain_from_email {
    my ( $self, $email ) = @_;
    my ( $address ) = Email::Address->parse( $email );
    return '' unless $address;
    return lc( $address->host );
}

sub recipient_probably_not_interested {
    my ( $self, $email ) = @_;
    my $domain = $self->extract_domain_from_email( $email );
    return 1 if !$domain;
    return !!grep { $domain eq $_ } @{ config()->{probably_uninterested} }
}

1;

