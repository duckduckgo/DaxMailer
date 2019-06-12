package Dancer2::Plugin::DaxMailer::Config;

# ABSTRACT: Set common configuration options

use Dancer2::Plugin;
use DaxMailer::Util::TemplateHelpers;
use File::Spec::Functions;
use File::Path qw/ make_path /;
use Carp;
use Hash::Merge::Simple qw/ merge /;

has home_directory => ( is => 'lazy' );
sub _build_home_directory {
    croak "Cannot retrieve home directory" unless $ENV{HOME};
    return $ENV{HOME};
}

has persistent_store => ( is => 'lazy' );
sub _build_persistent_store {
    my $dir = $ENV{DAXMAILER_PERSISTENT_STORE}
      || catdir( $_[0]->home_directory, 'ddgc' );
    make_path $dir unless -d $dir;
    return $dir;
}

sub _get_current_host {
    return $ENV{DAXMAILER_WEB_BASE} if $ENV{DAXMAILER_WEB_BASE};
    return ( $ENV{DAXMAILER_XMPP_DOMAIN} eq 'dukgo.com' )
        ? 'https://duck.co/'
        : 'https://ddgc-staging.duckduckgo.com/';
}

on_plugin_import {
    my ( $dsl ) = @_;
    my $settings = plugin_setting();

    $dsl->set(file_store => $dsl->persistent_store );

    $dsl->set(verify_sns => !$ENV{DAXMAILER_SNS_VERIFY_TEST});
    $dsl->set(charset => 'UTF-8');

    $dsl->set(base_url => _get_current_host);

    $dsl->set(basic_auth_user => $ENV{DAXMAILER_BASIC_AUTH_USER});
    $dsl->set(basic_auth_pass => $ENV{DAXMAILER_BASIC_AUTH_PASS});

    my $rootdir = $ENV{HOME};

    $dsl->set(effective_tld_names_url => $ENV{DAXMAILER_TLD_URL} ||
        'https://publicsuffix.org/list/effective_tld_names.dat' );
    $dsl->set(effective_tld_names => $ENV{DAXMAILER_TLD_FILE} ||
        catfile( $dsl->persistent_store, 'effective_tld_names.dat' ) );
    $dsl->set(probably_uninterested => [qw/ qq.com 126.com 163.com 139.com /]);

    $dsl->set(smtp_host => $ENV{DAXMAILER_SMTP_HOST});
    $dsl->set(smtp_ssl => $ENV{DAXMAILER_SMTP_SSL} // 0);
    $dsl->set(smtp_sasl_username => $ENV{DAXMAILER_SMTP_SASL_USERNAME});
    $dsl->set(smtp_sasl_password => $ENV{DAXMAILER_SMTP_SASL_PASSWORD});
    $dsl->set(mailgun_api_domain => $ENV{DAXMAILER_MAILGUN_API_DOMAIN});
    $dsl->set(mailgun_api_key => $ENV{DAXMAILER_MAILGUN_API_KEY});
    $dsl->set(use_smtp => $ENV{DAXMAILER_USE_SMTP});
    $dsl->set(bang_secret => $ENV{DAXMAILER_BANG_SECRET});

    my $dsn_cfgs = {
       'Pg' => {
            options => {
                pg_enable_utf8 => 1,
                on_connect_do => [
                    "SET client_encoding to UTF8",
                ],
                quote_char => '"',
            },
       },
       'SQLite' => {
           options => {
               sqlite_unicode => 1,
           }
       },
    };

    my $db_dsn = $ENV{DAXMAILER_DB_DSN} // "dbi:SQLite:$rootdir/daxmailer.sqlite";
    my $db_user = $ENV{DAXMAILER_DB_USER};
    my $db_password = $ENV{DAXMAILER_DB_PASSWORD};
    my $rdbms = $db_dsn =~ s/dbi:([a-zA-Z]+):.*/$1/r;

    $dsl->set(
        plugins => {
            %{ $dsl->config->{plugins} },
            DBIC => {
                default => {
                    dsn          => $db_dsn,
                    user         => $db_user,
                    password     => $db_password,
                    schema_class => 'DaxMailer::Schema',
                    %{ $dsn_cfgs->{ $rdbms } },
                }
            },
        },
    );

    $dsl->set(legacy_db_dsn => $ENV{LEGACY_DB_DSN} || 'dbi:Pg:database=ddgc');
    $dsl->set(legacy_db_user => $ENV{LEGACY_DB_USER} || 'ddgc');
    $dsl->set(legacy_db_password => $ENV{LEGACY_DB_PASSWORD});

    $dsl->set(layout => 'main');
    $dsl->set(views => './');

    $dsl->set(
        engines  => {
            ( $dsl->config->{engines} )
            ? %{ $dsl->config->{engines} }
            : (),
            template => {
                Xslate => {
                    path      => 'views',
                    cache_dir => "$rootdir/.xslate",
                    cache     => 1,
                    function  =>
                        DaxMailer::Util::TemplateHelpers->new(
                            app => $dsl
                        )->functions,
                },
            }
        }
    );

    $dsl->set(template => 'Xslate');

    my $campaigns = +{
        'a' => {
            single_opt_in => 1,
            live => 1,
            verify => {
                subject => 'Tracking in Incognito?',
                template => 'email/a/1.tx'
            },
            verify_page_template => 'email/a/verify.tx',
            unsub_page_template  => 'email/a/unsub.tx',
            layout => 'email/a/layout.tx',
            mails => {
                2 => {
                    days     => 2,
                    subject  => 'Are Ads Following You?',
                    template => 'email/a/2.tx',
                },
                3 => {
                    days     => 4,
                    subject  => 'Are Ads Costing You Money?',
                    template => 'email/a/3.tx',
                },
                4 => {
                    days     => 6,
                    subject  => 'Have You Deleted Your Google Search History Yet?',
                    template => 'email/a/4.tx',
                },
                5 => {
                    days     => 8,
                    subject  => 'Is Your Data Being Sold?',
                    template => 'email/a/5.tx',
                },
                6 => {
                    days     => 11,
                    subject  => 'Who Decides What Websites You Visit?',
                    template => 'email/a/6.tx',
                },
                10 => {
                    days     => 18,
                    subject  => 'Privacy Mythbusting #1: Nobody else cares about privacy!',
                    template => 'email/a/10.tx',
                },
                11 => {
                    days     => 25,
                    subject  => 'Privacy Mythbusting #2: My password keeps me safe',
                    template => 'email/a/11.tx',
                },
                12 => {
                    days     => 31,
                    subject  => 'Privacy Mythbusting #3: Anonymized data is safe, right?',
                    template => 'email/a/12.tx',
                },
                13 => {
                    days     => 38,
                    subject  => 'Privacy Mythbusting #4: I can\'t be identified just by browsing a website!',
                    template => 'email/a/13.tx',
                },
                14 => {
                    days     => 45,
                    subject  => 'Privacy Mythbusting #5: I own my personal information',
                    template => 'email/a/14.tx',
                },
                15 => {
                    days     => 53,
                    subject  => 'Privacy Mythbusting #6: Security equals privacy!',
                    template => 'email/a/15.tx',
                },
                20 => {
                    days     => 60,
                    subject  => 'How to Send Messages in Private',
                    template => 'email/a/20.tx',
                },
                21 => {
                    days     => 66,
                    subject  => 'How to Live Without Google',
                    template => 'email/a/21.tx',
                },
                22 => {
                    days     => 73,
                    subject  => 'How to Choose a Good VPN',
                    template => 'email/a/22.tx',
                },
                23 => {
                    days     => 80,
                    subject  => 'How to Set Up Your Devices for Privacy Protection',
                    template => 'email/a/23.tx',
                },
                24 => {
                    days     => 86,
                    subject  => 'How to Encrypt Your Devices',
                    template => 'email/a/24.tx',
                },
                25 => {
                    days     => 93,
                    subject  => 'How to Be Even More Anonymous Online',
                    template => 'email/a/25.tx',
                },
                26 => {
                    days     => 100,
                    subject  => 'How to Check Whether Your Web Connection\'s Secure',
                    template => 'email/a/26.tx',
                },
                27 => {
                    days     => 107,
                    subject  => 'DuckDuckGo Privacy Newsletter: 100-Day Follow-Up',
                    template => 'email/a/27.tx',
                },
                extension => {
                    oneoff   => 1,
                    subject  => 'DuckDuckGo news: Protecting privacy beyond the search box',
                    template => 'email/oneoff/extension.tx',
                    expires  => '2018-01-25',
                },
                crowdfunding => {
                    oneoff   => 1,
                    subject  => 'Join the $500,000 DuckDuckGo Privacy Challenge Crowdfunding Campaign',
                    template => 'email/oneoff/crowdfunding.tx',
                    expires  => '2018-04-10',
                },
            }
        },
        'b' => {
            base => 'a',
            single_opt_in => 1,
            verify => {
                subject => 'Tracking in Incognito?',
                template => 'email/a/1b.tx'
            }
        },
        'c' => {
            base => 'a',
            single_opt_in => 0,
            verify_layout => 'email/a/verify_layout.tx',
            template_map => 'c',
            mails => {
                1 => {
                    days     => 1,
                    subject => 'Tracking in Incognito?',
                    template => 'email/a/1c.tx',
                },
            }
        },
        'friends' => {
            single_opt_in => 1,
            plain_text => 1,
            layout => 'email/friends/layout.tx',
        }
    };

    for my $campaign ( keys %{ $campaigns } ) {
        if ( my $base = $campaigns->{ $campaign }->{base} ) {
            if ( $campaigns->{ $base } ) {
                $campaigns->{ $campaign } = merge( $campaigns->{ $base }, $campaigns->{ $campaign } );
            }
            else {
                die "Base $base does not exist - cannot build campaign $campaign"
            }
        }
    };

    $dsl->set(campaigns => $campaigns);

    $dsl->set(mailtrain_proto => $ENV{MAILTRAIN_PROTO} || 'https' );
    $dsl->set(mailtrain_host => $ENV{MAILTRAIN_HOST});
    $dsl->set(mailtrain_port => $ENV{MAILTRAIN_PORT});
    $dsl->set(mailtrain_access_token => $ENV{MAILTRAIN_ACCESS_TOKEN});
    $dsl->set(mailtrain_list => $ENV{MAILTRAIN_LIST});

};

register_plugin;

1;
