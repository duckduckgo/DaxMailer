#!/usr/bin/env perl

use FindBin;
use lib $FindBin::Dir . "/../lib";
use DaxMailer::Script::MigrateDDGC;

DaxMailer::Script::MigrateDDGC->new->go;
