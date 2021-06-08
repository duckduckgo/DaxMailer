#!/usr/bin/env perl

use FindBin;
use lib $FindBin::Dir . "/../lib";
use DaxMailer::Script::DeleteUnsubbed;

use DaxMailer::Script::DeleteUnsubbed->new->go;
