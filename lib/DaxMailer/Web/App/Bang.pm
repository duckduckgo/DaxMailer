package DaxMailer::Web::App::Bang;

use DaxMailer::Base::Web::Light;
use Try::Tiny;

post '/newbang' => sub {
    rset('Bang')->create_from_post( body_parameters )
        && return template 'bang';
    status 500;
    return 'Something went wrong';
}

1;
