package Dancer2::Plugin::DaxMailer::Config;

# ABSTRACT: Set common configuration options

use Dancer2;
use Dancer2::Plugin;
use DaxMailer::Util::TemplateHelpers;

on_plugin_import {
    my ( $dsl ) = @_;
    my $settings = plugin_setting();

    $dsl->set(verify_sns => !$ENV{DaxMailer_SNS_VERIFY_TEST});
    $dsl->set(charset => 'UTF-8');

    $dsl->set(base_url => 'https://mailer.duckduckgo.com/');

    $dsl->set(basic_auth_user => $ENV{DAXMAILER_BASIC_AUTH_USER});
    $dsl->set(basic_auth_pass => $ENV{DAXMAILER_BASIC_AUTH_PASS});

    my $rootdir = $ENV{HOME};
#    if ( $config->is_live ) {
#        $dsl->set( environment => 'production' );
#    }
#    elsif ( $config->is_view ) {
#        $dsl->set( environment => 'staging' );
#    }

    $dsl->set(smtp_host => $ENV{DAXMAILER_SMTP_HOST});
    $dsl->set(smtp_ssl => $ENV{DAXMAILER_SMTP_SSL} // 0);
    $dsl->set(smtp_sasl_username => $ENV{DAXMAILER_SMTP_SASL_USERNAME});
    $dsl->set(smtp_sasl_password => $ENV{DAXMAILER_SMTP_SASL_PASSWORD});

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

    my $db_dsn = $ENV{DAXMAILER_DB_DSN} // "dbi:SQLite:$rootdir/daxmailer.db.sqlite";
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
