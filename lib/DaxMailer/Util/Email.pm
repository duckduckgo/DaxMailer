use strict;
use warnings;
package DaxMailer::Util::Email;
# ABSTRACT: Send Xslate template email

use Text::Xslate;
use HTML::FormatText::WithLinks;
use Email::MIME;
use Email::Sender::Simple qw/ try_to_sendmail /;
use Email::Sender::Transport::Mailgun;
use Email::Sender::Transport::SMTP::Persistent;
use Email::Sender::Transport::Test;
use Email::Simple;
use HTTP::Validate qw/ :keywords :validators /;

use Moo;

has plaintext_renderer => ( is => 'lazy' );
sub _build_plaintext_renderer {
    HTML::FormatText::WithLinks->new(
        unique_links => 1,
    );
}

has xslate_text => ( is => 'lazy' );
sub _build_xslate_text {
    Text::Xslate->new(
        path => 'views',
        type => 'text',
    );
}

has xslate => ( is => 'lazy' );
sub _build_xslate {
    Text::Xslate->new(
        path => 'views',
    );
}

has use_smtp => (
    is => 'ro',
);

has smtp_config => (
    is => 'ro',
);

has mailgun_config => (
    is => 'ro',
);

has transport => ( is => 'lazy' );
sub _build_transport {
    my ( $self ) = @_;
    return Email::Sender::Transport::Test->new if $ENV{DAXMAILER_MAIL_TEST};
    return ( $self->use_smtp )
      ? Email::Sender::Transport::SMTP::Persistent->new( $self->smtp_config )
      : Email::Sender::Transport::Mailgun->new( $self->mailgun_config );
}

has validator => ( is => 'lazy' );
sub _build_validator {
    my ( $self ) = @_;
    my $v = HTTP::Validate->new( allow_unrecognized => 1 );

    $v->define_ruleset( 'send_parameters',
        {   mandatory => 'to',
            valid     => ANY_VALUE,
            errmsg    => 'To: address required',
        },
        {   mandatory => 'verified',
            valid     => POS_VALUE,
            errmsg    => 'Cannot send email without verification',
        },
        {   mandatory => 'from',
            valid     => ANY_VALUE,
            errmsg    => 'From: address required',
        },
        {   mandatory => 'subject',
            valid     => ANY_VALUE,
            errmsg    => 'Subject line required',
        },
        {   mandatory => 'content',
            valid     => ANY_VALUE,
            errmsg    => 'Email content required',
        },
        {   mandatory => 'template',
            valid     => ANY_VALUE,
            errmsg    => 'Template filename required',
        },
    );

    return $v;
}

sub _header {
    my ( $self, $params ) = @_;
    my $header = [
        map { $_ => $params->{$_} } (qw/ to from subject /),
    ];
    push @{ $header }, %{ $params->{extra_headers} } if $params->{extra_headers};
    return $header;
}

sub send_plaintext {
    my ( $self, $params ) = @_;
    my $v = $self->validator->check_params( 'send_parameters', {}, $params );

    if ( scalar $v->errors ) {
        return +{
            ok => 0,
            errors => [
                $v->errors,
            ]
        }
    }

    my $body = $self->xslate->render(
        $params->{template},
        {
            %{ $params->{content} },
            text => $params->{text}
        }
    );
    my $header = $self->_header( $params );
    my $email = Email::MIME->create(
        attributes => {
            content_type => 'text/plain; charset="UTF-8"',
            content_transfer_encoding => 'quoted-printable',
            charset => 'UTF-8',
            encoding => 'quoted-printable',
        },
        header_str => $header,
        body_str => $body,
    );

    if ( !try_to_sendmail( $email, { transport => $self->transport } ) ) {
        return {
            ok => 0,
            errors => [
                'sendmail error'
            ],
        }
    }

    return { ok => 1 };
}

sub send {
    my ( $self, $params ) = @_;
    my $v = $self->validator->check_params( 'send_parameters', {}, $params );

    if ( scalar $v->errors ) {
        return +{
            ok => 0,
            errors => [
                $v->errors,
            ]
        }
    }

    my $body = $self->xslate->render( $params->{template}, $params->{content} );
    $body = $self->xslate->render(
        $params->{layout},
        { content => $body, (
            $params->{content}
                ? %{ $params->{content} }
                : ()
        ) },
    ) if $params->{layout};

    my $html_part = Email::MIME->create(
        attributes => {
            content_type => 'text/html; charset="UTF-8"',
            content_transfer_encoding => 'quoted-printable',
            charset => 'UTF-8',
            encoding => 'quoted-printable',
        },
        body_str => $body,
    );

    my $plaintext_body = $self->plaintext_renderer->parse( $body );
    my $plaintext_part = Email::MIME->create(
        attributes => {
            content_type => 'text/plain; charset="UTF-8"',
            content_transfer_encoding => 'quoted-printable',
            charset => 'UTF-8',
            encoding => 'quoted-printable',
        },
        body_str => $plaintext_body,
    );

    my $header = $self->_header( $params );

    my $email = Email::MIME->create(
        attributes => {
            content_type => 'multipart/alternative',
        },
        header_str => $header,
        parts => [
            $plaintext_part,
            $html_part,
        ],
    );

    if ( !try_to_sendmail( $email, { transport => $self->transport } ) ) {
        return {
            ok => 0,
            errors => [
                'sendmail error'
            ],
        }
    }

    return { ok => 1 };
}

sub DESTROY {
    my ( $self ) = @_;
    $self->transport->disconnect if $self->transport->can('disconnect');
}

1;
