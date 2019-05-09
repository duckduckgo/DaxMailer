package DaxMailer::Schema;

# ABSTRACT: DBIC Schema base class

use Moo;
extends 'DBIx::Class::Schema';

use FindBin;
my $sqldir = $FindBin::Dir . "/../sql/";
our $VERSION = 6;

has app => (
    is => 'rw',
);

sub format_datetime {
    my $self = shift;
    $self->storage->datetime_parser->format_datetime(@_);
}

sub generate_diff {
    my ( $self, $previous_version ) = @_;

    $self->create_ddl_dir(
        [ qw/ PostgreSQL SQLite / ],
        $self->schema_version,
        $sqldir,
        $previous_version
    );
}

sub deploy_or_upgrade {
    my ( $self ) = @_;

    if ( $self->get_db_version ) {
        $self->upgrade;
    }
    else {
        $self->deploy;
    }
}

__PACKAGE__->load_components(qw/ Helper::Schema::QuoteNames /);
if ( ! $ENV{DAXMAILER_TEST} ) {
    __PACKAGE__->load_components(qw/ Schema::Versioned /);
    __PACKAGE__->upgrade_directory($sqldir);
}
__PACKAGE__->load_namespaces();

1;
