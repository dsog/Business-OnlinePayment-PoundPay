package Business::OnlinePayment::PoundPay;

use strict;
use warnings;
use Business::OnlinePayment;
use PoundPay;
use AutoLoader;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter AutoLoader Business::OnlinePayment);
@EXPORT = qw();
@EXPORT_OK = qw();
$VERSION = '1.0';

sub set_defaults {
    my $self = shift;

    $self->server('');
    $self->port('');
    $self->path('');

    $self->build_subs('order_number');
}

sub remap_fields {
    my ($self, %map) = @_;

    my %content = $self->content();

    # ACTION MAP
    my %actions = ('normal authorization' => 'ESCROWED',
                   'authorization only'   => 'CREATED',
                   'post authorization'   => 'ESCROWED',
                   'credit'               => 'RELEASED',
                   'void'                 => 'CANCELED',
                  );
    $content{action} = $actions{lc($content{action})} || $content{action};

    foreach(keys %map) {
        $content{$map{$_}} = $content{$_};
    }
    $self->content(%content);
}

sub get_fields {
    my($self,@fields) = @_;

    my %content = $self->content();
    my %new = ();
    foreach( grep defined $content{$_}, @fields) { $new{$_} = $content{$_}; }
    return %new;
}

sub submit {
    my($self) = @_;

    # Check for minimum required fields
    $self->required_fields(qw/login password action/);

    $self->remap_fields(
        duty           => 'payer_fee_amount',
        freight        => 'recipient_fee_amount',
        email          => 'payer_email_address',
        customer_id    => 'recipient_email_address',
        order_number   => 'sid' # ==> Payment_ID
    );

    my %content = $self->content;
    if( $content{action} eq 'CREATED' ) {
        $self->required_fields(qw/login password action amount duty freight
                                  email customer_id/);
    } elsif ( $content{action} eq 'ESCROWED' ) {
        $self->required_fields(qw/login password action sid/);
    }

    my $pp;
    if ( $self->test_transaction ) {
        $pp = PoundPay->new(
            developer_sid => $content{login},
            auth_token => $content{password}
        );
    } else {
        $pp = PoundPay->new(
            developer_sid => $content{login},
            auth_token => $content{password},
            api_url => 'https://api.poundpay.com/'
        );
    }

    $content{amount} =~ s/\D//g if $content{amount}; # strip non-digits

    # Submit the transaction to poundpay.
    my $result;
    if ( $content{action} eq 'CREATED' ) {
        $result = $pp->create_payment(
            $content{amount}, $content{payer_fee_amount}, 
            $content{recipient_fee_amount}, $content{payer_email_address},
            $content{recipient_email_address}, $content{description}
        );
    } elsif ( $content{action} eq 'ESCROWED' ) {
        $result = $pp->escrow_payment( $content{sid} );
    } elsif ( $content{action} eq 'RELEASED' ) {
        $result = $pp->release_payment( $content{sid} );
    } elsif ( $content{action} eq 'CANCELED' ) {
        $result = $pp->cancel_payment( $content{sid} );
    }

    # Handle result/responses
    if ( $result->{success} ){
        $self->is_success(1);
        $self->order_number($result->{sid});
        $self->result_code($result->{status});
    } else {
        $self->is_success(0);
        $self->error_message($result->{error});
    }

}

sub get_transaction_details {
    my ($self, $dev_sid, $token, $payment_sid) = @_;
    my $pp = PoundPay->new($dev_sid, $token);
    return $pp->get_payment($payment_sid);
}

sub get_account {
    my ($self, $dev_sid, $token) = @_;
    my $pp = PoundPay->new($dev_sid, $token);
    return $pp->get_account($dev_sid);
}

sub update_account {
    my ($self, $dev_sid, $token, $data) = @_;
    my $pp = PoundPay->new($dev_sid, $token);
    return $pp->update_account($dev_sid, $data);
}

1;
__END__
