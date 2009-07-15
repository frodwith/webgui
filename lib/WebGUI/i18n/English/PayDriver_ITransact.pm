package WebGUI::i18n::English::PayDriver_ITransact;

use strict;

our $I18N = {
    'emailMessage' => { 
        message     => q{Email message},
        lastUpdated => 0,
        context     => q{Form label in the configuration form of the iTransact module.},
    },
    'emailMessage help' => { 
        message     => q{The message that will be appended to the email user will receive from ITransact.},
        lastUpdated => 0,
        context     => q{Hover help for the email message field in the configuration form of the iTransact module.},
    },
    'extra info' => { 
        message     => q{Setting up your ecommerce site is as easy as these few steps:
<p>
<b>Step 1: Get A Merchant Account</b><br />
<a target="_blank" href="http://www.itransact.com/info/merchacct.html">Register for a merchant account now to get started processing online transactions.</a>
</p>

<p>
<b>Step 2: Set Up Your Merchant Account Info</b><br />
See the information toward the bottom of this page to set up your merchant account info.
</p>

<p>
<b>Step 3: Get An SSL Certificate</b><br />
<a target="_blank" href="http://www.completessl.com/plainblack.php">Get an SSL Certificate from CompleteSSL.</a>
</p>

<p>
<b>Step 4: Install The Certificate</b><br />
Contact your hosting provider to install your certificate or install it yourself.
</p>


<p>
<b>Step 5: Enable IP Address</b><br />
For added security the system will not allow just anyone to post requests to the merchant account. We have to tell the merchant account what the IP address of our site (or sites) is. To do this go to your virtual terminal and log in. Go to Account Settings &gt; Fraud Control &gt; and click on the "IP Filter Settings" link. There enter the IP address of your server Set the status to Active and set the module to XML, then hit go. Contact your system administrator for your server IP address. You'll also need to <a href="http://support.paymentclearing.com/">submit a support ticket</a> to let iTransact know that you wish to enable the XML API.
</p>

<p>
<b>Step 6: Enable The Commerce System</b><br />
Set the enabled field to "Yes" in your WebGUI commerce settings.
</p>

<p>
<b>Step 7: Optionally Accept American Express, Discover, and Diners Club</b><br />
By default you'll only be able to accept MasterCard and Visa. If you want to accept others you'll need to follow these steps:
<ol>
	<li>Call the credit card vendor to apply:
		<ul>
		<li>American Express: (800) 528-5200</li>
		<li>Discover: (800) 347-2000</li>
		<li>Diners Club: (800) 525-7376</li> 
		</ul>
	</li>
	<li><a href="http://support.paymentclearing.com/">Submit the account numbers that you get from those companies in a support ticket.</a> to get them registered with your merchant account.</li>
	<li>Go to your virtual terminal and enable these cards under your Account settings.</li>
</ol>
</p>

<hr />

This plugin expects that you set up the following recipe's in your iTransact account. Be very careful to enter the recipe names exactly as given below.<br />
<table border="0" cellpadding="3" cellspacing="0">
  <tr>
    <td align="right"><b>weekly</b></td>
    <td> -> </td>
    <td align="left">7 days</td>
  </tr>
  <tr>
    <td align="right"><b>biweekly</b></td>
    <td> -> </td>
    <td align="left">14 days</td>
  </tr>
   <tr>
    <td align="right"><b>fourweekly</b></td>
    <td> -> </td>
    <td align="left">28 days</td>
  </tr>
  <tr>
    <td align="right"><b>monthly</b></td>
    <td> -> </td>
    <td align="left">30 days</td>
  </tr>
  <tr>
    <td align="right"><b>quarterly</b></td>
    <td> -> </td>
    <td align="left">91 days</td>
  </tr>
  <tr>
    <td align="right"><b>halfyearly</b></td>
    <td> -> </td>
    <td align="left">182 days</td>
  </tr>
  <tr>
    <td align="right"><b>yearly</b></td>
    <td> -> </td>
    <td align="left">365 days</td>
  </tr>
</table><br />
Please note that some of these recipe's are only roughly correct. They don't 'fit' exactly in a whole year. Below the affected recipe's are given together with their difference on a year's basis. <br />
<ul>
  <li><b>monthly</b> (differs 5 days each year, 6 days each leap year)</li>
  <li><b>quarterly</b> (differs 1 day each year, 2 days each leap year)</li>
  <li><b>halfyearly</b> (differs 1 day each year, 2 days each leap year)</li>
  <li><b>yearly</b> (differs 1 day each leap year)</li>
</ul><br />
Also set the 'RECURRING POST-BACK URL' field in the Account Settings part of the virtual terminal to:},
        lastUpdated => 1189004971,
        context     => q{An informational message that's shown in the configuration form of this plugin.},
    },
    'name' => { 
        message     => q{Credit Card (ITransact)},
        lastUpdated => 1247593695,
        context     => q{Name of the ITransact Module},
    },
    'password' => { 
        message     => q{Password},
        lastUpdated => 0,
        context     => q{Form label in the configuration form of the iTransact module.},
    },
    'password help' => { 
        message     => q{The password for your ITransact account.},
        lastUpdated => 0,
        context     => q{Hover help for the password field in the configuration form of the iTransact module.},
    },
};

1;

#vim:ft=perl
