package WebGUI::Macro::PrevNext;

use strict;

=head1 NAME

Package WebGUI::Macro::PrevNext

=head1 DESCRIPTION

Provide a JS based previous and next button for each page, doing a depth-first
search one level deep.

=head2 process( $session, $topPage )

The main macro class, Macro.pm, will call this subroutine and pass it options.

=over 4

=item $session

A session variable

=item $topPage

The assetId of the top page.  The Macro will not look above this page.

=back

=cut


#-------------------------------------------------------------------
sub process {
	my ($session, $topPageId) = @_;
    my $topPage;
    if ($topPageId) {
        $topPage = WebGUI::Asset->newByDynamicClass($session, $topPageId);
    }
    if (! defined $topPage) {
        $topPage = WebGUI::Asset->getDefault($session);
    }
    my $nextPage = getNext($session->asset, $topPage);
	my $output = ""; # do some stuff
	return $output;
}

=head2 getNext ($startingAsset, $topPage)

Find the next asset using a 1-level, depth first approach.  This means it
prefers children over siblings.  If no next asset exists, it returns undef.
If it does exist, it returns an WebGUI::Asset object of the appropriate type.

=head3 $startingAsset

The next asset will be the next logical asset after $startingAsset.

=head3 $topPage

When no valid next sibling is found, the subroutine will attempt to
see if the parent has valid siblings with children.  It uses $topPage
to make sure it doesn't recurse out of a particular area, such as
all the way back to the WebGUI root node.

=cut

sub getNext {
    my ($startingAsset, $topPage) = @_;
    my $session = $startingAsset->session;
    my $childrenIterator = $startingAsset->getLineageIterator(
        ['children'],
        {
            includeOnlyClasses => ['WebGUI::Asset::Wobject::Layout'],
            returnObjects      => 1,
        }
    );
    my $firstChild = $childrenIterator->();
    if (defined $firstChild) {
        return $firstChild;
    }
    ##No children, try the first sibling after me
    my $firstAsset = $startingAsset;
    while ($firstAsset->getId ne $topPage->getId) {
        my $siblingIterator = $firstAsset->getLineageIterator(
            ['siblings'],
            {
                includeOnlyClasses => ['WebGUI::Asset::Wobject::Layout'],
                returnObjects      => 1,
                whereClause        => 'asset.lineage > '.$session->db->quote($firstAsset->get('lineage')),
            }
        );

        my $firstSib = $siblingIterator->();
        if (defined $firstSib) {
            return $firstSib;
        }
        $firstAsset = $firstAsset->getParent;
    }
    ##No valid siblings after me, try my parent's siblings.
    return undef;
}

=head2 getPrevious

Find the next asset using a 1-level, depth first approach.  This means
it prefers children over siblings.  If no previous asset exists, it
returns undef.  If it does exist, it returns an WebGUI::Asset object of
the appropriate type.

=head3 $startingAsset

The next asset will be the next logical asset after $startingAsset.

=head3 $topPage

When no valid next sibling is found, the subroutine will attempt to
see if the parent has valid siblings with children.  It uses $topPage
to make sure it doesn't recurse out of a particular area, such as
all the way back to the WebGUI root node.

=cut

sub getPrevious {
    my ($startingAsset, $topPage) = @_;
    if ($startingAsset->getId eq $topPage->getId) {
        return $topPage;
    }
    my $session = $startingAsset->session;
    my $siblingIterator = $startingAsset->getLineageIterator(
        ['siblings'],
        {
            includeOnlyClasses => ['WebGUI::Asset::Wobject::Layout'],
            whereClause        => 'asset.lineage < '.$session->db->quote($startingAsset->get('lineage')),
            returnObjects      => 1,
            invertTree         => 1,
        }
    );

    my $firstSib = $siblingIterator->();
    if (defined $firstSib) {
        return $firstSib;
    }
    return $startingAsset->getParent();
}

1;

#vim:ft=perl