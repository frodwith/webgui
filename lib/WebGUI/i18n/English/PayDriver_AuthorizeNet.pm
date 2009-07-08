package WebGUI::i18n::English::PayDriver_ITransact;
use strict;

our $I18N = {
	'login' => {
		message => q|Login|,
		lastUpdated => 0,
		context => q|Form label in the configuration form of the AuthorizeNet module.|
	},
	'login help' => {
		message => q|The login for your Authroize.net account.|,
		lastUpdated => 0,
		context => q|Hover help for the login field of the AuthorizeNet module|
	},
	'password' => {
		message => q|Password|,
		lastUpdated => 0,
		context => q|Form label in the configuration form of the AuthorizeNet module.|
	},
	'password help' => {
		message => q|The password for your Authorize.net account.|,
		lastUpdated => 0,
		context => q|Hover help for the password field of the AuthorizeNet module|
	},
    'test mode' => {
        message => 'Test Mode',
        lastUpdated => 0,
        context => 'Form label for test mode toggle in AuthroizeNet module',
    },
    'test mode help' => {
        message => 'Whether calls using this gateway should be made in test mode',
        lastUpdated => 0,
        context => 'Hover help for test mode form field',
    },
	'name' => {
		message => q|Credit Card (Authorize.net)|,
		lastUpdated => 0,
		context => q|Name of the Authorize.net module|
	},
};

1;
