#!/usr/bin/env perl

use FindBin;
use lib $FindBin::Dir . "/../lib";
use DaxMailer::Script::VerifyLastSend;

DaxMailer::Script::VerifyLastSend->new_with_options->go;

