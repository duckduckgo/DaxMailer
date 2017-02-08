use strict;
use warnings;
package DaxMailer::Base::Script::Service;

# ABSTRACT: Common elements of service architecture based script modules

use Moo::Role;
use DaxMailer::Base::Web::Common;

has app_config => ( is => 'lazy' );
sub _build_app_config {
    config;
}

1;
