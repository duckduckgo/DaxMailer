package Dancer2::Plugin::DaxMailer::Config;

# ABSTRACT: Set common configuration options

use Dancer2::Plugin;
use DaxMailer::Util::TemplateHelpers;
use File::Spec::Functions;
use File::Path qw/ make_path /;
use Carp;

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
};

register_plugin;

1;
