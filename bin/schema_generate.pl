#!/usr/bin/env perl

use FindBin;
use lib $FindBin::Dir . "/../lib";
use DaxMailer::Base::Web::Light;
use Moo;
use MooX::Options;

option previous_version => (
    is     => 'lazy',
    format => 'i',
    short  => 'p',
    doc    => 'Previous schema version. Default is current version minus one'
);
sub _build_previous_version {
    ( schema->VERSION -1 ) // 0;
}

sub go {
    schema->generate_diff( $_[0]->previous_version );
}

main->new_with_options->go;
