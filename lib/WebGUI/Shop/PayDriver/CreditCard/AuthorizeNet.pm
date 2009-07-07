package WebGUI::Shop::PayDriver::CreditCard::AuthorizeNet;

use strict;

use base qw/WebGUI::Shop::PayDriver::CreditCard/;

#-------------------------------------------------------------------

=head2 cancelRecurringPayment ( transaction )

Cancels a recurring transaction. Returns an array containing ( isSuccess, gatewayStatus, gatewayError).

=head3 transaction

The instanciated recurring transaction object.

=cut

sub cancelRecurringPayment {
    my $self        = shift;
    my $transaction = shift;
    my $session     = $self->session;
    #### TODO: Throw exception

    # Get the payment definition XML
    my $xml = $self->_generateCancelRecurXml( $transaction );
    $session->errorHandler->debug("XML Request: $xml");

    # Post the xml to ITransact 
    my $response = $self->doXmlRequest( $xml, 1 );

    # Process response
	if ($response->is_success) {
		# We got some XML back from iTransact, now parse it.
        $session->errorHandler->info('Starting request');
        my $transactionResult = XMLin( $response->content );
		unless (defined $transactionResult->{ RecurUpdateResponse }) {
			# GatewayFailureResponse: This means the xml is invalid or has the wrong mime type
            $session->errorHandler->info( "GatewayFailureResponse: result: [" . $response->content . "]" );
            return( 
                0, 
                "Status: "      . $transactionResult->{ Status }
                ." Message: "   . $transactionResult->{ ErrorMessage } 
                ." Category: "  . $transactionResult->{ ErrorCategory } 
            );
		} else {
            # RecurUpdateResponse: We have succesfully sent the XML and it was correct. Note that this doesn't mean
            # that the cancellation has succeeded. It only has if Status is set to OK and the remaining terms is 0.
            $session->errorHandler->info( "RecurUpdateResponse: result: [" . $response->content . "]" );
            my $transactionData = $transactionResult->{ RecurUpdateResponse };

            my $status          = $transactionData->{ Status            };
            my $errorMessage    = $transactionData->{ ErrorMessage      };
            my $errorCategory   = $transactionData->{ ErrorCategory     };
            my $remainingTerms  = $transactionData->{ RecurDetails      }->{ RemReps    };
            
            # Uppercase the status b/c the documentation is not clear on the case.
            my $isSuccess       = uc( $status ) eq 'OK' && $remainingTerms == 0;
       
            return ( $isSuccess, "Status: $status Message: $errorMessage Category: $errorCategory" );
		}
	} else {
		# Connection Error
        $session->errorHandler->info("Connection error");

        return ( 0, undef, 'ConnectionError', $response->status_line );
	}
}

#-------------------------------------------------------------------
sub definition {
    my $class       = shift;
    my $session     = shift;
    my $definition  = shift;

    my $i18n = WebGUI::International->new($session, 'PayDriver_ITransact');

    tie my %fields, 'Tie::IxHash';
    %fields = (
        vendorId        => {
           fieldType    => 'text',
           label        => $i18n->get('vendorId'),
           hoverHelp    => $i18n->get('vendorId help'),
        },
        password        => {
            fieldType   => 'password',
            label       => $i18n->get('password'),
            hoverHelp   => $i18n->get('password help'),
        },
        credentialsTemplateId  => {
            fieldType    => 'template',
            label        => $i18n->get('credentials template'),
            hoverHelp    => $i18n->get('credentials template help'),
            namespace    => 'Shop/Credentials',
            defaultValue => 'itransact_credentials1',	
        },
        # readonly stuff from old plugin here?
    );
 
    push @{ $definition }, {
        name        => $i18n->get('Itransact'),
        properties  => \%fields,
    };

    return $class->SUPER::definition($session, $definition);
}

#-------------------------------------------------------------------
sub handlesRecurring { 1 }

#-------------------------------------------------------------------

=head2 processPayment ($transaction)

Contact ITransact and submit the payment data to them for processing.

=head3 $transaction

A WebGUI::Shop::Transaction object to pull information from.

=cut

sub processPayment {
    my $self        = shift;
    my $transaction = shift;
    my $session     = $self->session;

    # Get the payment definition XML
    my $xml = $self->_generatePaymentRequestXML( $transaction );
    $session->errorHandler->debug("XML Request: $xml");

    # Send the xml to ITransact
    my $response = $self->doXmlRequest( $xml );

    # Process response
	if ($response->is_success) {
		# We got some XML back from iTransact, now parse it.
        my $transactionResult = XMLin( $response->content,  SuppressEmpty => '' );

#### TODO: More checking: price, address, etc
		unless (defined $transactionResult->{ TransactionData }) {
			# GatewayFailureResponse: This means the xml is invalid or has the wrong mime type
            $session->errorHandler->info("GatewayFailureResponse: result: [".$response->content."]");
            return( 
                0, 
                undef, 
                $transactionResult->{ Status }, 
                $transactionResult->{ ErrorMessage } . ' Category: ' . $transactionResult->{ ErrorCategory } 
            );
		} else {
            # SaleResponse: We have succesfully sent the XML and it was correct. Note that this doesn't mean that
            # the transaction has succeeded. It only has if Status is set to OK.
            $session->errorHandler->info("SaleResponse: result: [".$response->content."]");
            my $transactionData = $transactionResult->{ TransactionData };

            my $status          = $transactionData->{ Status            };
            my $errorMessage    = $transactionData->{ ErrorMessage      };
            my $errorCategory   = $transactionData->{ ErrorCategory     };
            my $gatewayCode     = $transactionData->{ XID               };
            my $isSuccess       = $status eq 'OK';
       
            my $message = ($errorCategory) ? " $errorMessage Category: $errorCategory" : $errorMessage;

            return ( $isSuccess, $gatewayCode, $status, $message );
		}
	} else {
		# Connection Error
        $session->errorHandler->info("Connection error");

        return ( 0, undef, 'ConnectionError', $response->status_line );
	}
}

#-------------------------------------------------------------------

=head2 www_edit ( )

Generates an edit form.

=cut

sub www_edit {
    my $self    = shift;
    my $session = $self->session;
    my $admin   = WebGUI::Shop::Admin->new($session);
    my $i18n    = WebGUI::International->new($session, 'PayDriver_ITransact');

    return $session->privilege->insufficient() unless $admin->canManage;

    my $form = $self->getEditForm;
    $form->submit;

    my $terminal = WebGUI::HTMLForm->new($session, action=>"https://secure.paymentclearing.com/cgi-bin/rc/sess.cgi", extras=>'target="_blank"');
    $terminal->hidden(name=>"ret_addr", value=>"/cgi-bin/rc/sure/sure.cgi?sure_template_code=session_check&sure_use_session_mid=1");
    $terminal->hidden(name=>"override", value=>1);
    $terminal->hidden(name=>"cookie_precheck", value=>0);
    $terminal->hidden(name=>"mid", value=>$self->get('vendorId'));
    $terminal->hidden(name=>"pwd", value=>$self->get('password'));
    $terminal->submit(value=>$i18n->get('show terminal'));
    
    my $output = '<br />';
    if ($self->get('vendorId')) {
        $output .= $terminal->print.'<br />';
    }
    $output .= $i18n->get('extra info').'<br />'
            .'<b>https://'.$session->config->get("sitename")->[0]
            .'/?shop=pay;method=do;do=processRecurringTransactionPostback;paymentGatewayId='.$self->getId.'</b>';

    return $admin->getAdminConsole->render($form->print.$output, $i18n->get('payment methods','PayDriver'));
}

#-------------------------------------------------------------------

=head2 www_processRecurringTransactionPostback 

Callback method for ITransact to dial up WebGUI and post the results of a
recurring transaction.  This allows WebGUI to renew group memberships or
do whatever other activity a Sku purchase would allow.

=cut

sub www_processRecurringTransactionPostback {
	my $self    = shift;
    my $session = $self->session;
	$session->http->setMimeType('text/plain');
    my $form    = $session->form;

    # Get posted data of interest
    my $originatingXid  = $form->process( 'orig_xid'        );
    my $status          = $form->process( 'status'          );
    my $xid             = $form->process( 'xid'             );
    my $errorMessage    = $form->process( 'error_message'   );

    # Fetch the original transaction
    my $baseTransaction = eval{WebGUI::Shop::Transaction->newByGatewayId( $session, $originatingXid, $self->getId )};

    #---- Check the validity of the request -------
    # First check whether the original transaction actualy exists
    if (WebGUI::Error->caught || !(defined $baseTransaction) ) {   
        $session->errorHandler->warn("Check recurring postback: No base transction for XID: [$originatingXid]");
	$session->http->setStatus('500', "No base transction for XID: [$originatingXid]");
        return "Check recurring postback. No base transction for XID: [$originatingXid]";
    }

    # Secondly check if the postback is coming from secure.paymentclearing.com
    # This will most certainly fail on mod_proxied webgui instances
#    unless ( $ENV{ HTTP_HOST } eq 'secure.paymentclearing.com') {
#        $session->errorHandler->info('ITransact Recurring Payment Postback is coming from host: ['.$ENV{ HTTP_HOST }.']');
#        return;
#    }

    # Third, check if the new xid exists and if the amount is correct.
#    my $expectedAmount = sprintf("%.2f", 
#        $baseTransaction->get('amount') + $baseTransaction->get('taxes') + $baseTransaction->get('shippingPrice') );

#    unless ( $self->checkRecurringTransaction( $xid, $expectedAmount ) ) {
#        $session->errorHandler->warn('Check recurring postback: transaction check failed.');
 #       return 'Check recurring postback: transaction check failed.';
#    }
    #---- Passed all test, continue ---------------

    #make sure the same user is used in this transaction as the last {mostly needed for reoccurring transactions
    $self->session->user({userId=>$baseTransaction->get('userId')});
 
    # Create a new transaction for this term
    my $transaction     = $baseTransaction->duplicate( {
        originatingTransactionId    => $baseTransaction->getId,  
    });

    # Check the transaction status and act accordingly
    if ( uc $status eq 'OK' ) {
        # The term was succesfully payed
        $transaction->completePurchase( $xid, $status, $errorMessage );
    }
    else {
        # The term has not been payed succesfully
        $transaction->denyPurchase( $xid, $status, $errorMessage );
    }

    return "OK";
}

1;

