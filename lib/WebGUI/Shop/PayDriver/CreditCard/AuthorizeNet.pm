package WebGUI::Shop::PayDriver::CreditCard::AuthorizeNet;

use strict;

use base qw/WebGUI::Shop::PayDriver::CreditCard/;

use DateTime;
use Readonly;
use Business::OnlinePayment;

Readonly my $I18N => 'PayDriver_AuthorizeNet';

#-------------------------------------------------------------------

sub appendCredentialVars {
    my ($self, $var) = @_;
    my $session = $self->session;
    $self->SUPER::appendCredentialVars($var);

    $var->{cardTypeField} = WebGUI::Form::SelectList($session, {
        name    => 'cardType',
        value   => $session->form->process('cardType'),
        options => {
            VISA       => 'Visa',
            MASTERCARD => 'Mastercard',
            AMEX       => 'American Express',
            DISCOVER   => 'Discover',
        },
    });

    return;
}

#-------------------------------------------------------------------

=head2 cancelRecurringPayment ( transaction )

Cancels a recurring transaction. Returns an array containing ( isSuccess, gatewayStatus, gatewayError).

=head3 transaction

The instanciated recurring transaction object.

=cut

sub cancelRecurringPayment {
    my ($self, $transaction) = @_;
    my $session = $self->session;

    my $tx = $self->gatewayObject;
    $tx->content(
        subscription => $transaction->get('transactionCode'),
        login        => $self->get('login'),
        password     => $self->get('password'),
        action       => 'Cancel Recurring Authorization',
    );
    $tx->submit;

    return $self->gatewayResponse($tx);
}

#-------------------------------------------------------------------
sub definition {
    my ($class, $session, $definition) = @_;

    my $i18n = WebGUI::International->new($session, $I18N);

    tie my %fields, 'Tie::IxHash', (
        login           => {
           fieldType    => 'text',
           label        => $i18n->get('login'),
           hoverHelp    => $i18n->get('login help'),
        },
        password        => {
            fieldType   => 'password',
            label       => $i18n->get('password'),
            hoverHelp   => $i18n->get('password help'),
        },
        testMode        => {
            fieldType   => 'YesNo',
            label       => $i18n->get('test mode'),
            hoverHelp   => $i18n->get('test mode help'),
        },
        # readonly stuff from old plugin here?
    );
 
    push @{ $definition }, {
        name        => $i18n->get('name'),
        properties  => \%fields,
    };

    return $class->SUPER::definition($session, $definition);
}

#-------------------------------------------------------------------

=head2 gatewayObject ( params )

Returns a Business::OnlinePayment object, possibly with options set from the
paydriver properties.  params can be a hashref of the options that would
normally be passed to tx->content, in which case these will be passed along.

=cut

sub gatewayObject {
    my ($self, $params) = @_;

    my $tx = Business::OnlinePayment->new('AuthorizeNet');
    $tx->test_transaction( $self->get('testMode') );
    $tx->content(%$params) if $params;

    return $tx;
}

#-------------------------------------------------------------------

=head2 gatewayResponse ( tx )

Returns the various responses required by the PayDriver interface from the
passed Business::OnlinePayment object.

=cut

sub gatewayResponse {
    my ($self, $tx) = @_;
    return (
        $tx->isSuccess, 
        $tx->order_number, 
        $tx->result_code, 
        $tx->error_message,
    );
}

#-------------------------------------------------------------------

sub handlesRecurring { 1 }

#-------------------------------------------------------------------

=head2 paymentParams

Returns a hashref of the billing address and card information, translated into
a form that Business::OnlinePayment likes

=cut

sub paymentParams {
    my $self = shift;
    my $card = $self->{_cardData};
    my $bill = $self->{_billingAddress};

    my %params = (
        type        => $card->{type},
        login       => $self->get('login'),
        password    => $self->get('password'),
        first_name  => $bill->{firstName},
        last_name   => $bill->{lastName},
        address     => $bill->{address1},
        city        => $bill->{city},
        state       => $bill->{state},
        zip         => $bill->{code},
        card_number => $card->{acct},
        expiration  => sprintf '%2d/%2d', @{$card}{'expMonth', 'expYear'},
    );
    $params{cvv2} = $card->{cvv2} if $self->get('useCVV2');
    return \%params;
}

#-------------------------------------------------------------------

sub processCredentials {
    my $self    = shift;
    my $session = $self->session;
	my $i18n    = WebGUI::International->new($session, $I18N);
    my $error   = $self->SUPER::processCredentials;

    my $type = $session->form->process('cardType');
    
    push @$errors, $i18n->get( 'invalid cardType' ) unless $type;

    return $error if @$error;
    
    $self->{_cardData}->{type} = $type;

    return;
}

#-------------------------------------------------------------------

sub processPayment {
    my ($self, $transaction) = @_;
    my $params = $self->paymentParams;

    if ($transaction->isRecurring) {
        my $items = $transaction->getItems;
        if (@$items > 1) {
            WebGUI::Error::InvalidParam->throw(error => 
                'This payment gateway can only handle one recurring item at a time'
            );
        }

        my $item  = $items->[0];
        my $sku   = $item->getSku;

        my %translateInterval = (
            Weekly     => '7 days',
            BiWeekly   => '14 days',
            FourWeekly => '28 days',
            Monthly    => '1 month',
            Quarterly  => '3 months',
            HalfYearly => '6 months',
            Yearly     => '12 months',
        );

        $params->{action}      = 'Recurring Authorization';
        $params->{interval}    = $translateInterval{ $sku->getRecurInterval };
        $params->{start}       = DateTime->today->ymd;
        $params->{periods}     = '9999'; # magic value that means 'never stop'
        $params->{description} = $item->get('configuredTitle');
    }
    else {
        $params->{action} = 'Normal Authorization';
    }

    $params->{amount} = $transaction->get('amount');
    my $tx = $self->gatewayObject($params);
    $tx->submit;
    return $self->gatewayResponse($tx);
}

1;

