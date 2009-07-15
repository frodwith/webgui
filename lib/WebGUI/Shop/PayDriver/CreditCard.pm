package WebGUI::Shop::PayDriver::CreditCard;

use strict;
use Readonly;

=head1 NAME

WebGUI::Shop::PayDriver::CreditCard

=head2 DESCRIPTION

A base class for credit card payment drivers.  They all need pretty much the
same information, the only difference is the servers you talk to.  Leaves you
to handle recurring payments, processPayment, www_edit, and whatever else you
want to - but the user-facing code is pretty much taken care of.

=head2 METHODS

The following methods are available from this class.

=cut

use base qw/WebGUI::Shop::PayDriver/;

Readonly my $I18N => 'PayDriver_CreditCard';

#-------------------------------------------------------------------
sub _monthYear {
    my $session = shift;
    my $form    = $session->form;

	tie my %months, "Tie::IxHash";
	tie my %years,  "Tie::IxHash";
	%months = map { sprintf( '%02d', $_ ) => sprintf( '%02d', $_ ) } 1 .. 12;
	%years  = map { $_ => $_ } 2004 .. 2099;

    my $monthYear =
        WebGUI::Form::selectBox( $session, {
            name    => 'expMonth',
            options => \%months,
            value   => [ $form->process("expMonth") ]
        })
        . " / "
        . WebGUI::Form::selectBox( $session, {
            name    => 'expYear',
            options => \%years,
            value   => [ $form->process("expYear") ]
        });

    return $monthYear;
}

#-------------------------------------------------------------------

=head2 appendCredentialVars

Add template vars for www_getCredentials.  Override this to add extra fields.

=cut

sub appendCredentialVars {
    my ($self, $var) = @_;
    my $session = $self->session;
	my $u       = $session->user;
    my $form    = $session->form;
    my $i18n    = WebGUI::International->new($session, $I18N);

    # Process address from address book if passed
    my $addressId   = $form->process( 'addressId' );
    my $addressData;
    if ( $addressId ) {
        $addressData    = eval{ $self->getAddress( $addressId )->get() } || {};
    }
    else {
        $addressData    = $self->getCart->getShippingAddress->get;
    }

    $var->{getSelectAddressButton} = $self->getSelectAddressButton( 'getCredentials' );

    $var->{formHeader} = WebGUI::Form::formHeader($session)
                       . $self->getDoFormTags('pay');

    if ($var->{formHeader}) {
        $var->{formHeader} .= WebGUI::Form::hidden($session, {name => 'addressId', value => $addressId});
    }

    $var->{formFooter} = WebGUI::Form::formFooter();

    my @fields = (
        {
            name  => 'firstName',
            label => 'firstName',
            addr  => 'firstName',
            prof  => 'firstName',
        },
        {
            name  => 'lastName',
            label => 'lastName',
            addr  => 'lastName',
            prof  => 'lastName',
        },
        {
            name  => 'address',
            label => 'address',
            addr  => 'address1',
            prof  => 'homeAddress',
        },
        {
            name  => 'city',
            label => 'city',
            addr  => 'city',
            prof  => 'homeCity'
        },
        {
            name  => 'state',
            label => 'state',
            addr  => 'state',
            prof  => 'homeState',
        },
        {
            name  => 'zipcode',
            label => 'code',
            addr  => 'code',
            prof  => 'homeZip'
        },
        {
            name  => 'country',
            label => 'country',
            type  => 'country',
            addr  => 'country',
            prof  => 'homeCountry',
            def   => 'United States',
        },
        {
            name  => 'phone',
            label => 'phone number',
            type  => 'phone',
            addr  => 'phoneNumber',
            prof  => 'homePhone',
        },
        {
            name  => 'email',
            label => 'email',
            type  => 'email',
            addr  => 'email',
            prof  => 'email',
        },
    );

    my ($shopText, $ccText) = map {
        WebGUI::International->new($session, $_)
    } qw(Shop PayDriver_CreditCard);

    my @fieldLoop;

    foreach my $f (@fields) {
        my $name  = $f->{name};
        my $type  = $f->{type} || 'text';

        my $value = $form->process($name, $type);
        $value ||= $addressData->{ $f->{addr} }   if $f->{addr};
        $value ||= $u->profileField( $f->{prof} ) if $f->{prof};

        no strict 'refs';
        my $make = "WebGUI::Form::$type";
        push @fieldLoop, {
            label => $shopText->get( $f->{label} ),
            name  => $name,
            field => $make->($session, { name => $name, value => $value }),
        };
    }

    push @fieldLoop, {
        name  => 'cardNumber',
        label => $ccText->get('cardNumber'),
        field => WebGUI::Form::text($session, {
            name  => 'cardNumber', 
            value => $form->process('cardNumber')
        }),
    };

    push @fieldLoop, {
        name  => 'monthYear',
        label => $ccText->get('expiration date'),
        field => _monthYear( $session ),
    };

    push @fieldLoop, {
        name  => 'cvv2',
        label => $ccText->get('cvv2'),
        field => WebGUI::Form::integer($session, {
            name  => 'cvv2',
            value => $form->process('cvv2'),
        }),
    } if $self->get('useCVV2');

    $var->{fields} = \@fieldLoop;

    $var->{checkoutButton} = WebGUI::Form::submit($session, {
        value => $i18n->get('checkout button', 'Shop'),
    });

    return;
}

#-------------------------------------------------------------------
sub definition {
    my ($class, $session, $definition) = @_;

    my $i18n = WebGUI::International->new($session, $I18N);

    tie my %fields, 'Tie::IxHash', (
        useCVV2         => {
            fieldType   => 'yesNo',
            label       => $i18n->get('use cvv2'),
            hoverHelp   => $i18n->get('use cvv2 help'),
        },
        credentialsTemplateId  => {
            fieldType    => 'template',
            label        => $i18n->get('credentials template'),
            hoverHelp    => $i18n->get('credentials template help'),
            namespace    => 'Shop/Credentials',
            defaultValue => 'itransact_credentials1',
        },
    );

    push @{ $definition }, {
        name        => 'Credit Card Base Class',
        properties  => \%fields,
    };

    return $class->SUPER::definition($session, $definition);
}

#-------------------------------------------------------------------

=head2 getButton

Return a form to select this payment driver and to accept credentials from those
who wish to use it.

=cut

sub getButton {
    my $self    = shift;
    my $session = $self->session;

    return WebGUI::Form::formHeader($session)
        . $self->getDoFormTags('getCredentials')
        . WebGUI::Form::submit($session, {value => $self->get('label') })
        . WebGUI::Form::formFooter($session);
}

#-------------------------------------------------------------------

=head2 processCredentials

Process the form where credentials (name, address, phone number and credit card information)
are entered.

=cut

sub processCredentials {
    my $self    = shift;
    my $session = $self->session;
    my $form    = $session->form;
	my $i18n    = WebGUI::International->new($session, $I18N);
    my @error;

    # Check address data
	push @error, $i18n->get( 'invalid firstName'    ) unless $form->process( 'firstName' );
	push @error, $i18n->get( 'invalid lastName'     ) unless $form->process( 'lastName'  );
	push @error, $i18n->get( 'invalid address'      ) unless $form->process( 'address'   );
	push @error, $i18n->get( 'invalid city'         ) unless $form->process( 'city'      );
	push @error, $i18n->get( 'invalid email'        ) unless $form->email  ( 'email'     );
	push @error, $i18n->get( 'invalid zip'          )
        if ( !$form->zipcode( 'zipcode' ) && $form->process( 'country' ) eq 'United States' );

    # Check credit card data
	push @error, $i18n->get( 'invalid card number'  ) unless $form->integer('cardNumber');
	push @error, $i18n->get( 'invalid cvv2'         ) if ($self->get('useCVV2') && !$form->integer('cvv2'));

	# Check if expDate and expYear have sane values
	my ($currentYear, $currentMonth) = $self->session->datetime->localtime;
    my $expires = $form->integer( 'expYear' ) . sprintf '%02d', $form->integer( 'expMonth' );
    my $now     = $currentYear                . sprintf '%02d', $currentMonth;

    push @error, $i18n->get('invalid expiration date') unless $expires =~ m{^\d{6}$};
    push @error, $i18n->get('expired expiration date') unless $expires >= $now;

	return \@error if scalar @error;
    # Everything ok process the actual data
    $self->{ _cardData } = {
        acct		=> $form->integer( 'cardNumber' ),
        expMonth	=> $form->integer( 'expMonth'   ),
        expYear		=> $form->integer( 'expYear'    ),
        cvv2		=> $form->integer( 'cvv2'       ),
    };

    $self->{ _billingAddress } = {
        address1	=> $form->process( 'address'    ),
        code	    => $form->zipcode( 'zipcode'    ),
        city		=> $form->process( 'city'       ),
        firstName	=> $form->process( 'firstName'  ),
        lastName	=> $form->process( 'lastName'   ),
        email		=> $form->email  ( 'email'      ),
        state		=> $form->process( 'state'      ),
        country		=> $form->process( 'country'    ),
        phoneNumber => $form->process( 'phone'      ),
    };

    return;
}

#-------------------------------------------------------------------

=head2 getBillingAddress ( $addressId )

The billing address is not handled by WebGUI::Shop::Address, it comes from
www_getCredentials.  However, WebGUI::Shop::Transaction requires an
WebGUI::Shop::Address object.  The billing address is seeded with information
from the shipping address.  If this address info is different, then create
a new address to hand to Transaction.

=head3 $addressId

The id of a WebGUI::Shop::Address.  If not present, then use the shipping
address instead.

=cut

sub getBillingAddress {
    my ($self, $addressId) = @_;

    my $address     = $addressId
                    ? $self->getAddress( $addressId )
                    : $self->getCart->getShippingAddress
                    ;

    ##If the user made any changes to the default address, create a new billing address
    ##and use it instead
    if( $address->get('firstName'   ) ne $self->{_billingAddress}->{ 'firstName'    }
     || $address->get('lastName'    ) ne $self->{_billingAddress}->{ 'lastName'     }
     || $address->get('address1'    ) ne $self->{_billingAddress}->{ 'address1'     }
     || $address->get('city'        ) ne $self->{_billingAddress}->{ 'city'         }
     || $address->get('state'       ) ne $self->{_billingAddress}->{ 'state'        }
     || $address->get('code'        ) ne $self->{_billingAddress}->{ 'code'         }
     || $address->get('country'     ) ne $self->{_billingAddress}->{ 'country'      }
     || $address->get('phoneNumber' ) ne $self->{_billingAddress}->{ 'phoneNumber'  }
     || $address->get('email'       ) ne $self->{_billingAddress}->{ 'email'        }
    ) {
        my $billingAddress = $self->getCart->getAddressBook->addAddress( $self->{_billingAddress} );
        return $billingAddress;
    }
    return $address;
}

#-------------------------------------------------------------------

=head2 www_getCredentials ( $errors )

Build a templated form for asking the user for their credentials.

=head3 $errors

An array reference of errors to show the user.

=cut

sub www_getCredentials {
    my $self        = shift;
    my $errors      = shift;
    my $session     = $self->session;
    my $form        = $session->form;
    my $i18n        = WebGUI::International->new($session, $I18N);
    my $var = {};

# Process form errors
    $var->{errors} = [];
    if ($errors) {
        $var->{error_message} = $i18n->get('error occurred message');
        foreach my $error (@{ $errors} ) {
            push @{ $var->{errors} }, { error => $error };
        }
    }

    $self->appendCredentialVars($var);

    # Just in case the template author wants to use the fields by name, set
    # that up too
    foreach my $f (@{ $var->{fields} }) {
        $var->{ "$f->{name}Field" } = $f->{field};
    }

    my $template = WebGUI::Asset::Template->new($session, $self->get("credentialsTemplateId"));
    my $output;
    if (defined $template) {
        $template->prepare;
        $output = $template->process($var);
    }
    else {
        $output = $i18n->get('template gone');
    }

    return $session->style->userStyle($output);
}

#-------------------------------------------------------------------

=head2 www_pay

Makes sure that the user has all the requirements for checking out, including
getting credentials, it processes the transaction and then displays a thank
you screen.

=cut

sub www_pay {
    my $self        = shift;
    my $session     = $self->session;
    # Check whether the user filled in the checkout form and process those.
    my $credentialsErrors = $self->processCredentials;

    # Go back to checkout form if credentials are not ok
    return $self->www_getCredentials( $credentialsErrors ) if $credentialsErrors;

    my $addressId       = $session->form->process( 'addressId' );
    my $billingAddress  = $self->getBillingAddress($addressId);
    my $shippingAddress = $self->getCart->getShippingAddress;

    # Payment time!
    my $transaction = $self->processTransaction( $billingAddress );

    ## The billing address object is temporary, just to send to the transaction.
    ## Delete it if we don't need it.
    my $temp = $billingAddress->getId eq $addressId
        ||     $billingAddress->getId ne $shippingAddress->getId;
    $billingAddress->delete if $temp;

	if ($transaction->get('isSuccessful')) {
	    return $transaction->thankYou();
	}

    # Payment has failed...
    return $self->displayPaymentError($transaction);
}

1;

