#!/usr/bin/env perl

# Development server builder.
# See dev_server.sh

use strict;
use warnings;

use FindBin;
use lib $FindBin::Dir . "/../lib";

use Plack::Builder;
use DaxMailer::Web::Service::Bounce;
use DaxMailer::Web::App::Subscriber;

builder {
    enable 'StackTrace', force => 1;
    mount '/s' => DaxMailer::Web::App::Subscriber->to_app;
    mount '/bounce' => DaxMailer::Web::Service::Bounce->to_app;
};

