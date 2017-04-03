package DaxMailer::Base::Web::Service;

# ABSTRACT: Base module for JSON web services

use Import::Into;

use strict;
use warnings;
use utf8;

use DaxMailer::Base::Web::Common;
use Dancer2::Plugin::DaxMailer::Service;
use Dancer2::Plugin::DaxMailer::Bailout;

{   no warnings 'redefine';
    sub import {
        my ($caller, $filename) = caller;
        for (
          qw/
            strict
            warnings
            utf8
            Dancer2
          /
        ) {
            $_->import::into($caller);
        }
        Dancer2::Plugin::DaxMailer::Config->import::into( $caller );
        for (
          qw/
            DaxMailer::Base::Web::Common
            Dancer2::Plugin::DaxMailer::Service
            Dancer2::Plugin::DaxMailer::Bailout
          /
        ) {
            $_->import::into($caller);
        }
    }
};

1;
