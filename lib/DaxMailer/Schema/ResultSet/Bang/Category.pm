package DaxMailer::Schema::ResultSet::Bang::Category;

use Moo;
extends 'DaxMailer::Schema::ResultSet';

sub toplevel {
    $_[0]->search({ parent => undef })
}

1;
