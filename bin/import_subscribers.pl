#!/usr/bin/env perl

use FindBin;
use lib $FindBin::Dir . "/../lib";
use DaxMailer::Script::ImportSubscribers;

DaxMailer::Script::ImportSubscribers->new_with_options->go;
