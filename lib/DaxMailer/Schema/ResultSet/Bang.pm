package DaxMailer::Schema::ResultSet::Bang;

use Moo;
extends 'DaxMailer::Schema::ResultSet';

use Try::Tiny;

sub create_from_post {
    my ( $self, $body ) = @_;
    my ( $category, $subcategory );
    my $bang;

    try {
        $category = $self->rs('Bang::Category')->find_or_create({
            name   => $body->{bang_cat},
            parent => undef,
        }) or die "Unable to retrieve category";

        $subcategory = $self->rs('Bang::Category')->find_or_create({
            name   => $body->{bang_subcat},
            parent => $category->id,
        }) or die "Unable to retrieve subcategory";

        $bang = $self->create({
            command       => $body->{bang_command},
            url           => $body->{bang_url},
            email_address => $body->{from},
            site_name     => $body->{bang_site},
            comments      => $body->{bang_comments},
            category_id   => $subcategory->id,
        }) or die "Unable to create bang";
    } catch {
        return 0;
    };

    return $bang;
}

1;
