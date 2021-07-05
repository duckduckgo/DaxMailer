#!/usr/bin/env perl

use FindBin;
use lib $FindBin::Dir . "/../lib";
use DaxMailer::Script::PurgeMailgun;

DaxMailer::Script::PurgeMailgun->new->go;
