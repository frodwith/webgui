package WebGUI::i18n::English::PayDriver_CreditCard;
use strict;

our $I18N = {
	'cardNumber' => {
		message => q|Credit card number|,
		lastUpdated => 1101772177,
		context => q|Form label in the checkout form of the Credit Card module.|
	},
	'credentials template' => {
		message => q|Credentials Template|,
		lastUpdated => 0,
		context => q|Form label in the configuration form of the Credit Card module.|
	},
   	'credentials template help' => {
		message => q|Pick a template to display the form where the user will enter in their billing information and credit card information.|,
		lastUpdated => 0,
		context => q|Hover help for the credentials template field in the configuration form of the Credit Card module.|
	},
	'cvv2' => {
		message => q|Verification number (ie. CVV2)|,
		lastUpdated => 1101772182,
		context => q|Form label in the checkout form of the Credit Card module.|
	},
    'error occurred message' => {
        message => q|The following errors occurred:|,
        lastUpdated => 0,
        context => q|The message that tell the user that there were some errors in their submitted credentials.|,
    },
	'expiration date' => {
		message => q|Expiration date|,
		lastUpdated => 1101772180,
		context => q|Form label in the checkout form of the Credit Card module.|
	},
	'expired expiration date' => {
		message => q|The expiration date on your card has already passed.|,
		lastUpdated => 0,
		context => q|An error indicating that an an expired card was used.|
	},
	'invalid firstName' => {
		message => q|You have to enter a valid first name.|,
		lastUpdated => 0,
		context => q|An error indicating that an invalid first name has been entered.|
	},
	'invalid lastName' => {
		message => q|You have to enter a valid last name.|,
		lastUpdated => 0,
		context => q|An error indicating that an invalid last name has been entered.|
	},
	'invalid address' => {
		message => q|You have to enter a valid address.|,
		lastUpdated => 0,
		context => q|An error indicating that an invalid street has been entered.|
	},
	'invalid city' => {
		message => q|You have to enter a valid city.|,
		lastUpdated => 0,
		context => q|An error indicating that an invalid city has been entered.|
	},
	'invalid zip' => {
		message => q|You have to enter a valid zipcode.|,
		lastUpdated => 0,
		context => q|An error indicating that an invalid zipcode has been entered.|
	},
	'invalid email' => {
		message => q|You have to enter a valid email address.|,
		lastUpdated => 0,
		context => q|An error indicating that an invalid email address has been entered.|
	},
	'invalid card number' => {
		message => q|You have to enter a valid credit card number.|,
		lastUpdated => 0,
		context => q|An error indicating that an invalid credit card number has been entered.|
	},
	'invalid cvv2' => {
		message => q|You have to enter a valid card security code (ie. cvv2).|,
		lastUpdated => 0,
		context => q|An error indicating that an invalid card security code has been entered.|
	},
	'invalid expiration date' => {
		message => q|You have to enter a valid expiration date.|,
		lastUpdated => 0,
		context => q|An error indicating that an invalid expiration date has been entered.|
	},
	'template gone' => {
		message => q|The template for entering in credentials has been deleted.  Please notify the site administrator.|,
		lastUpdated => 0,
		context => q|Error message when the getCredentials template cannot be accessed.|
	},
	'use cvv2' => {
		message => q|Use CVV2|,
		lastUpdated => 0,
		context => q|Form label in the configuration form of the Credit Card module.|
	},
	'use cvv2 help' => {
		message => q|Set this option to yes if you want to use CVV2.|,
		lastUpdated => 0,
		context => q|Form label in the configuration form of the Credit Card module.|
	},
};

1;
