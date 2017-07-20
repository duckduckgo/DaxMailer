package Plack::Middleware::Throttle::Lite::Backend::FastMmap;

# ABSTRACT: Cache backend for Throttle::Lite

use strict;
use warnings;
use Cache::FastMmap;
use parent 'Plack::Middleware::Throttle::Lite::Backend::Abstract';

our $_storage = Cache::FastMmap->new(
    serializer => '',
    expire_time => '1h',
);

sub reqs_done {
    my ($self) = @_;
    $_storage->get( $self->cache_key ) // 0;
}

sub increment {
    my ($self) = @_;
    $_storage->get_and_set( $self->cache_key, sub { return ++$_[1]; });
}

1;
