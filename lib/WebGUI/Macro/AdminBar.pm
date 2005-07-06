package WebGUI::Macro::AdminBar;

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2005 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

use strict qw(refs vars);
use Tie::CPHash;
use Tie::IxHash;
use WebGUI::AdminConsole;
use WebGUI::Asset;
use WebGUI::Asset::Template;
use WebGUI::Grouping;
use WebGUI::International;
use WebGUI::Macro;
use WebGUI::Session;
use WebGUI::SQL;
use WebGUI::URL;
use WebGUI::Utility;

#-------------------------------------------------------------------
sub process {
	return "" unless ($session{var}{adminOn});
	my @param = WebGUI::Macro::getParams($_[0]);
        my $templateId = $param[0] || "PBtmpl0000000000000090";
        my %var;
	my (%cphash, %hash2, %hash, $r, @item, $query);
	tie %hash, "Tie::IxHash";
	tie %hash2, "Tie::IxHash";
	tie %cphash, "Tie::CPHash";
	$var{'packages.canAdd'} = ($session{user}{uiLevel} >= 7);
	$var{'packages.label'} = WebGUI::International::get(376,'Macro_AdminBar');
	$var{'contentTypes.label'} = WebGUI::International::get(1083,'Macro_AdminBar');
	$var{'clipboard.label'} = WebGUI::International::get(1082,'Macro_AdminBar');
	if (exists $session{asset}) {
		foreach my $package (@{$session{asset}->getPackageList}) {
			my $title = $package->getTitle;
			$title =~ s/'//g; # stops it from breaking the javascript menus
                	push(@{$var{'package_loop'}},{
				'url'=>$session{asset}->getUrl("func=deployPackage&assetId=".$package->getId),
				'label'=>$title,
				'icon.small'=>$package->getIcon(1),
				'icon'=>$package->getIcon()
				});
        	}
		$var{contentTypes_loop} = $session{asset}->getAssetAdderLinks;
		$var{container_loop} = $session{asset}->getAssetAdderLinks(undef,"assetContainers");
		foreach my $asset (@{$session{asset}->getAssetsInClipboard(1)}) {
			my $title = $asset->getTitle;
			$title =~ s/'//g; # stops it from breaking the javascript menus
			push(@{$var{clipboard_loop}}, {
				'label'=>$title,
				'url'=>$session{asset}->getUrl("func=paste&assetId=".$asset->getId),
				'icon.small'=>$asset->getIcon(1),
				'icon'=>$asset->getIcon()
				});
		}
	} 
   #--admin functions
	$var{adminConsole_loop} = WebGUI::AdminConsole->getAdminFunction;
	return WebGUI::Asset::Template->new($templateId)->process(\%var);
#		'http://validator.w3.org/check?uri=referer'=>WebGUI::International::get(399,'Macro_AdminBar'),
}




1;

