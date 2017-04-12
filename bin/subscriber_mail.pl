#!/usr/bin/env perl

use FindBin;
use lib $FindBin::Dir . "/../lib";
use DaxMailer::Script::SubscriberMailer;

DaxMailer::Script::SubscriberMailer->new_with_options->go;

