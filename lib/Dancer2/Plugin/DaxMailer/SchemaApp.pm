package Dancer2::Plugin::DaxMailer::SchemaApp;

# ABSTRACT: Set schema's app instance to current app.

use Dancer2::Plugin;

on_plugin_import {
    my ( $dsl ) = @_;
    my $plugin = $dsl->app->with_plugin('DBIC');
    $plugin->schema->can('app') && $plugin->schema->app($dsl);
};

register_plugin;

1;
