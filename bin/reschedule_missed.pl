#!/usr/bin/env perl

use FindBin;
use lib $FindBin::Dir . "/../lib";
use DaxMailer::Script::RescheduleMissed;

DaxMailer::Script::RescheduleMissed->new_with_options->go;

