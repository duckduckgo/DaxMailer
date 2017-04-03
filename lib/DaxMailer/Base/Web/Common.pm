package DaxMailer::Base::Web::Common;

# ABSTRACT: Base module with common configs / features for DaxMailer Apps and Services.

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
            Dancer2::Plugin::DaxMailer::Config
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
