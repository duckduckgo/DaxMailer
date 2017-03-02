#!/usr/bin/env perl

use FindBin;
use lib $FindBin::Dir . "/../lib";
use DaxMailer::Base::Web::Light;

schema->generate_diff;

1;
