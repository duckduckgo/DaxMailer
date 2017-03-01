package DaxMailer::Web::App::Bang;

use DaxMailer::Base::Web::Light;
use Try::Tiny;

post '/newbang' => sub {
    rset('Bang')->create_from_post( body_parameters )
        && return template 'bang/thanks', { layout => undef };
    status 500;
    return 'Something went wrong';
};

post '/newbangs.txt' => sub {
    content_type 'text/plain';
    if ( !body_parameters->{secret} ||
         body_parameters->{secret} ne config->{bang_secret} ) {
        status 401;
        return '';
    }
    my $pending = rset('Bang')->pending;
    my $tsv = $pending->tsv;
    $pending->moderate;
    return $tsv;
};

get '/test' => sub {
    template 'bang/testform', { layout => undef };
};

1;
