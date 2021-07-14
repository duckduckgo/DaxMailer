#!/usr/bin/env perl

use FindBin;
use lib $FindBin::Dir . "/../lib";
use DaxMailer::Script::DeletePCCGraduated;

DaxMailer::Script::DeletePCCGraduated->new->go;
