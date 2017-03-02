package DaxMailer::Schema::ResultSet::Subscriber::Bounce;

use Moo;
extends 'DaxMailer::Schema::ResultSet';

sub handle_bounces {
    my ( $self, $message ) = @_;
    my $update_params;
    my @emails;
    if ( $message->{notificationType} eq 'Bounce' && $message->{bounce}->{bounceType} eq 'Permanent' ) {
        $update_params = { bounced => 1 };
        push @emails, map { $_->{emailAddress} } @{$message->{bounce}->{bouncedRecipients}};
    }
    elsif ( $message->{notificationType} eq 'Complaint' ){
        $update_params = { complaint => 1 };
        push @emails, map { $_->{emailAddress} } @{$message->{complaint}->{complainedRecipients}};
    }

    return { ok => 1 } if !$update_params || !@emails;

    for my $email (@emails) {
        $self->update_or_create({ email_address => $email, %{ $update_params } });
    }

    return { ok => 1 };
}

1;
