package DaxMailer::Web::App::Subscriber;

# ABSTRACT: Subscriber management

use DaxMailer::Base::Web::Common;
use Dancer2::Plugin::Auth::HTTP::Basic::DWIW;
use DaxMailer::Script::SubscriberMailer;
use Email::Valid;

my $subscriber = DaxMailer::Script::SubscriberMailer->new;

http_basic_auth_set_check_handler sub {
    my ( $user, $pass ) = @_;
    return $user eq config->{basic_auth_user} && $pass eq config->{basic_auth_pass};
};

get '/u/:campaign/:email/:key' => sub {
    my $params = params('route');
    my $s = rset('Subscriber')->find( {
        email_address => $params->{email},
        campaign      => $params->{campaign},
    } );
    my $legacy_unsub = rset('Subscriber::Bounce')->legacy_unsub( $params->{email} );
    my $template =
        config->{campaigns}->{ $params->{campaign} }->{unsub_page_template} ||
        'email/unsub.tx';
    template $template,
             { success =>
                 ( ( $s && $s->unsubscribe( $params->{ key } ) ) ||
                 $legacy_unsub > 0 )
             },
             { layout => undef };
};

get '/v/:campaign/:email/:key' => sub {
    my $params = params('route');
    my $s = rset('Subscriber')->find( {
        email_address => $params->{email},
        campaign      => $params->{campaign},
    } );
    my $template =
        config->{campaigns}->{ $params->{campaign} }->{verify_page_template} ||
        'email/verify.tx';
    template $template,
             { success => (
                     $s && $s->verify( $params->{ key } )
                 )
             },
             { layout => undef };
};

get '/form' => sub {
    return <<"FORM"
    <form method="POST" action="/s/a">
        email: <input type="text" name="email"><br />
        campaign: <select name="campaign">
            <option value='a'>Extension</option>
            <option value='b'>Non-extension</option>
            <option value='c'>Spread</option>
        </select></br>
        from (Spread): <input type="text" name="from"><br />
        template (Spread): <select name="template">
            <option value='1'>Private browsing myths</option>
            <option value='2'>Ads Cost You Money</option>
            <option value='3'>Delete Your Google History</option>
        </select><br />
        <input type="hidden" name="flow" value="form">
        <input type="checkbox" name="page" id="page">
        <label for="page">
            Return Page
        </label><br />
        <input type="submit" name="submit">
    </form>
FORM
};

any qr{^/testrun} => http_basic_auth required => sub {
    pass;
};

get '/testrun' => sub {
    template 'email/testrun.tx';
};

get '/testrun/:campaign' => sub {
    forward '/testrun';
};

post '/testrun' => sub {
    my $routeparams = params('route');
    my $bodyparams = params('body');
    my $email = Email::Valid->address($bodyparams->{email});
    if ( !$email ) {
        var( message => "Error: valid email address required" );
    }
    else {
        my $extra = {};
        $extra->{from} = $bodyparams->{from} if $bodyparams->{from};
        $extra->{verify_only} = $bodyparams->{verify_only};
        $extra->{which} = $bodyparams->{which};
        DaxMailer::Script::SubscriberMailer->new->testrun(
            $bodyparams->{campaign},
            $bodyparams->{email},
            $extra
        );
        var( message => "Email sent to " . $bodyparams->{email} );
    }
    forward '/testrun', {}, { method => 'GET' };
};

any '/friends' => http_basic_auth required => sub {
    pass;
};

get '/friends' => sub {
    my $params = params;
    template 'email/friends/form.tx', {
        email_subject => $params->{email_subject} || 'DuckDuckGo Newsletter',
        email_body    => $params->{email_body},
        test_address  => $params->{test_address},
    }
};

post '/friends' => sub {
    my $params = params;
    if( $params->{send_list} ) {
        var message => $subscriber->queue_newsletter( $params );
    }
    elsif ( $params->{send_test} ) {
        var message => $subscriber->test_newsletter( $params );
    }
    else {
        var message => 'ERROR: Unknown action';
    }
    forward '/friends', {}, { method => 'GET' };
};

get '/a' => sub {
    template 'email/message',
        { title => 'Thank you!', message => 'Thank you!' },
        { layout => 'mail' };
};

post '/a' => sub {
    my $render_page = body_parameters->get('page');
    if ( ! rset('Subscriber')->add_from_post( body_parameters() ) ) {
        status 400;
        return "NOT OK" unless $render_page;
    }
    return "OK" unless $render_page;
    redirect '/a';
};

get '/add/:email' => sub {
    my $email = route_parameters->get('email');
    rset('Subscriber')->add_from_post({
        email => $email,
        campaign => 'b',
        flow => 'get',
    });
    return template 'email/message',
        { title => 'Thank you!', message => 'Thank you!' },
        { layout => 'mail' };
};

any qr{^/bulk} => http_basic_auth required => sub {
    pass;
};

get '/bulk' => sub {
    return <<"BULKFORM"
    <form method="POST" action="/s/bulk">
        <h3>email addresses:</h3>
        <textarea name="to" rows=40 cols=50></textarea><br/>
        <input type="hidden" name="flow" value="bulk">
        <input type="hidden" name="campaign" value="b">
        <input type="submit" name="submit">
    </form>
BULKFORM
};

post '/bulk' => sub {
    my $params = body_parameters();
    $params->add(
        to => join( ',', split( /[\s,\n]+/, $params->{to} ) )
    );
    rset('Subscriber')->add_from_post( $params );
    return "Thanks!";
};

1;
