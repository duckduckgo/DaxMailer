package DaxMailer::Base::Web::Light;

# ABSTRACT: Base module for simple, unintegrated web apps

# Drops: Sessions, user integration
# Keeps: Database

use Import::Into;

use strict;
use warnings;
use utf8;

use Dancer2;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::RootURIFor;
use Dancer2::Plugin::DaxMailer::Config;
use Dancer2::Plugin::DaxMailer::SchemaApp;

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
        Dancer2::Plugin::DaxMailer::Config->import::into( $caller, 'nosession' );
        for (
          qw/
            Dancer2::Plugin::DBIC
            Dancer2::Plugin::RootURIFor
            Dancer2::Plugin::DaxMailer::SchemaApp
          /
        ) {
            $_->import::into($caller);
        }
    }
};

1;
