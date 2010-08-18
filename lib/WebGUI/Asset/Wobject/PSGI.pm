#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2010 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

package WebGUI::Asset::Wobject::PSGI;

use warnings;
use strict;

use base qw(WebGUI::Asset::Wobject);

use File::Temp qw(tmpnam);
use WebGUI::International;
use WebGUI::User;
use HTTP::Status qw(status_message);
use Scope::Guard qw(guard);
use Digest::SHA q(sha1_hex);

#-------------------------------------------------------------------

=head2 canEdit ( )

Overridden so that one must be in the proper group to create these wobjects
(since they're sort of dangerous)

=cut

sub canEdit {
    my ( $self, $user ) = @_;
    my $session = $self->session;
    my $userId;
    $user ||= $session->user;
    if ( ref $user eq 'WebGUI::User' ) {
        $userId = $user->userId;
    }
    else {
        $userId = $user;
        $user = WebGUI::User->new( $session, $userId );
    }

    my $group = $session->setting->get('groupIdPSGIAssets');
    return $user->isInGroup($group) && $self->SUPER::canEdit($userId);
} ## end sub canEdit

# This code is adapated from Plack::Util::load_app.  The idea here is to dump
# the code into a file, do() the file in a scratch package, and get rid of the
# file.  We can't just eval the code -- there are several problems with that.
# String-evalled code has access to its lexical environment (not good), and
# it's harder to get it into a scratch package that way.  This is as sandboxed
# as we can make it, although obviously the Full Power of Perl is here.

sub _compile {
    my ( $chk, $code ) = @_;
    my $name = tmpnam;
    open my $fh, '>', $name;
    print $fh $code or die "Could not print to $name: $!\n";
    close $fh;

    my $cleanup = guard { unlink $name };
    eval sprintf( '{ package %s::_%s; do $name or die $@ || $! }', __PACKAGE__, $chk ) or die $@;
}

#-------------------------------------------------------------------

=head2 definition ( )

See the superclass for documentation.

=cut

sub definition {
    my ( $class, $session, $definition ) = @_;
    my $i18n = WebGUI::International->new( $session, 'Asset_PSGI' );
    my %properties = (
        app => {
            fieldType => 'codearea',
            syntax    => 'perl',
            label     => $i18n->get('app label'),
            hoverHelp => $i18n->get('app description'),
        }
    );
    my %def = (
        assetName         => $i18n->get('assetName'),
        icon              => 'psgi.png',
        autoGenerateForms => 1,
        tableName         => 'Asset_PSGI',
        className         => __PACKAGE__,
        properties        => \%properties,
    );
    push @$definition, \%def;
    return $class->SUPER::definition( $session, $definition );
} ## end sub definition

my @psgiVersion = ( 1, 1 );

#-------------------------------------------------------------------

=head2 dispatch ( $fragment )

See the superclass for documentation.  We will do "normal" asset dispatch
(func=blah -> www_blah) if there is no fragment and we have such a function
(www_add, etc), or if calling the PSGI app fails (because we can't compile it,
it throws an exception, or returns an invalid response).

=cut

sub dispatch {
    my ( $self, $fragment ) = @_;
    my $session = $self->session;
    my $func    = $session->form->get('func');
    my $bail    = sub { $self->SUPER::dispatch($fragment) };

    if ( !$fragment && $func && $self->can("www_$func") ) {
        return $bail->();
    }

    my ( $url, $r, $http, $out, $log ) = $session->quick(qw(url request http output log));

    my $app = $self->loadApp || return $bail->();

    open my $errh, '>', \my $err;
    my $cleanup = guard {
        close $errh;
        $log->error($err) if $err;
    };

    my $table = $r->subprocess_env;
    my $ssl = $table->{HTTP_SSLPROXY} || do {
        my $v = $table->{HTTPS};
        $v && ( $v eq '1' || $v eq 'on' );
    };

    my %env = (
        %$table,
        'SCRIPT_NAME'       => $self->getUrl,
        'PATH_INFO'         => $fragment,
        'psgi.version'      => \@psgiVersion,
        'psgi.url_scheme'   => $ssl ? 'https' : 'http',
        'psgi.input'        => $r,
        'psgi.errors'       => $errh,
        'psgi.multithread'  => 0,
        'psgi.multiprocess' => 1,
        'psgi.run_once'     => 0,
        'psgi.streaming'    => 0,
        'psgi.nonblocking'  => 0,
        'wgSession'         => $session,
        'wgAsset'           => $self,
    );

    my $response = eval { $app->( \%env ) };
    if ( ref $response ne 'ARRAY' || $@ ) {
        if ($@) {
            $log->error("psgi app died with $@");
        }
        else {
            $log->error(q"psgi app didn't return an arrayref");
        }
        return $bail->();
    }

    my ( $status, $headers, $body ) = @$response;

    $http->setStatus( $status, status_message($status) );

    my $hout = $status =~ /^2/ ? $r->headers_out : $r->err_headers_out;
    for my $i ( 0 .. $#$headers ) {
        my ( $k, $v ) = @{$headers}[ $i, $i + 1 ];
        my $lc = lc $k;
        if ( $lc eq 'content-type' ) {
            $http->setMimeType($v);
        }
        elsif ( $lc eq 'content-length' ) {
            $r->set_content_length($v);
        }
        $hout->add( $k => $v );
    }

    $http->sendHeader();

    if ( my $path = eval { $body->path } ) {
        $http->setStreamedFile($body);
    }
    elsif ( ref $body eq 'ARRAY' ) {
        $out->print($_) for @$body;
    }
    elsif ( eval { $body->can('getline') } ) {
        while ( defined( my $line = $body->getline ) ) {
            $out->print($line);
        }
    }
    else {
        $log->error("Don't know how to handle response $body");
        return $bail->();
    }

    return 'chunked';
} ## end sub dispatch

#-------------------------------------------------------------------

=head2 getContentLastModified ( )

This will always return the current time, since we have no concievable way of
knowing the answer.

=cut

sub getContentLastModified {time}

#-------------------------------------------------------------------

=head2 loadApp

Returns the CODE representing the PSGI app.  Code is only compiled once per
modperl process (unless there is a compilation error), and thereafter is
cached.

=cut

my %apps;

sub loadApp {
    my $self = shift;
    my $code = $self->get('app');
    my $chk  = sha1_hex($code);
    $apps{$chk} ||= do {
        my $a = eval { _compile( $chk, $code ) };
        $self->session->log->error($@) if ( !$a && $@ );
        $a;
    };
}

1;
