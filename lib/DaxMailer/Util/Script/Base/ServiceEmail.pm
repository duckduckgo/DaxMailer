use strict;
use warnings;
package DaxMailer::Util::Script::Base::ServiceEmail;

# ABSTRACT: Common elements of service architecture based email script modules

use Moo::Role;

use DaxMailer::Util::Email;

has smtp => (
    is => 'ro',
    lazy => 1,
    builder => '_build_smtp'
);
sub _build_smtp {
    my ( $self ) = @_;
    DaxMailer::Util::Email->new(
        smtp_config => {
            host          => $self->app_config->{smtp_host} // 'localhost',
            ssl           => $self->app_config->{smtp_ssl} // 0,
            sasl_username => $self->app_config->{smtp_sasl_username} // '',
            sasl_password => $self->app_config->{smtp_sasl_password} // '',
        }
    );
}

1;
