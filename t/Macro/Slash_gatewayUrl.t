#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2009 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

use FindBin;
use strict;
use lib "$FindBin::Bin/../lib";

use WebGUI::Test;
use WebGUI::Session;
use Data::Dumper;

use Test::More; # increment this value for each test you create

my $session = WebGUI::Test->session;

##Note, this is not a test of the gateway method.  That is done over
##in t/Session/Url.t  All we need to do is make sure that the macro
##fetches the same thing as the method.

my $numTests = 4;
$numTests += 1; #For the use_ok

plan tests => $numTests;

my $macro = 'WebGUI::Macro::Slash_gatewayUrl';
my $loaded = use_ok($macro);

SKIP: {

skip "Unable to load $macro", $numTests-1 unless $loaded;

$session->setting->set('preventProxyCache', 0);

my $output;

$output = WebGUI::Macro::Slash_gatewayUrl::process($session);
is($output, $session->url->gateway, 'fetching site gateway');

$output = WebGUI::Macro::Slash_gatewayUrl::process($session, '/foo/bar');
is($output, $session->url->gateway('/foo/bar'), 'passing URL through to macro');

$session->setting->set('preventProxyCache', 1);

$output = WebGUI::Macro::Slash_gatewayUrl::process($session);
like($output, qr{/\?noCache=\d+:\d+$}, 'checking the cache settings in the URL');

$output = WebGUI::Macro::Slash_gatewayUrl::process($session, '/foo/bar');
like($output, qr{/foo/bar\?noCache=\d+:\d+$}, 'checking the cache settings in the URL are at the end of the URL');

$session->setting->set('preventProxyCache', 0);

}

END {
}
