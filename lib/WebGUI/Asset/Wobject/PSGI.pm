#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2010 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

package WebGUI::Asset::Wobject::PSGI::Writer;

sub new {
    my ($class, $session) = @_;
    my $r = $session->request;
    bless sub { $r->print(@_); $r->rflush }, $class;
}

sub write {
    my $sub = shift;
    goto &$sub;
}

sub close { }

package WebGUI::Asset::Wobject::PSGI;

use warnings;
use strict;

use base qw(WebGUI::Asset::Wobject);

use HTTP::Status qw(status_message);
use Scope::Guard;

=head1 NAME

WebGUI::Asset::Wobject::PSGI

=head1 SYNOPSIS

    package WebGUI::Asset::Wobject::MyCoolApp;
    use base qw(WebGUI::Asset::Wobject::PSGI);

    my $app = __PACKAGE__->compileFile('/path/to/app.psgi');

    sub app { $app }

    sub getName { 'My Cool App' }

=head1 METHODS

=cut

#-------------------------------------------------------------------

=head2 app

Override this in subclasses.  Should return your PSGI app.

=cut

sub app { die 'Abstract' }

#-------------------------------------------------------------------

=head2 badApp ( $env )

Called when there's a problem executing the PSGI app.  By default, returns a
bare 500 response. It's called with the PSGI environment, although it isn't
used by default.

=cut

sub badApp { [500, [], [] ] }

#-------------------------------------------------------------------

=head2 callApp ( $app, $env )

Calls the given PSGI app with the given environment and does some
error-checking on the response.  Feel free to override.

=cut

sub callApp {
    my ( $self, $app, $env, $k ) = @_;
    my $log = $self->session->log;
    my $response = eval { $app->($env) };
    
    if ( !$response || $@ ) {
        $log->error("psgi app died with $@");
        $k->($self->badApp($env));
    }
    elsif (ref $response eq 'ARRAY') {
        $k->($response);
    }
    elsif (ref $response eq 'CODE') {
        $response->($k);
    }
    else {
        $log->error("Invalid response: $response");
        $k->($self->badApp($env));
    }
} ## end sub callApp

#-------------------------------------------------------------------

=head2 compileFile ( path )

Compiles the contents of the file given by path (like Plack::Util::load_app)
in sandbox and returns the resulting app.  Intended to be called in
subclasses -- see the Synopsis.

=cut

sub compileFile {
    my ( $class, $name ) = @_;
    my @letters = ( 'a' .. 'z', 'A' .. 'Z' );
    my $gibberish = join '', map { $letters[ int( rand( scalar @letters ) ) ] } ( 1 .. 48 );
    eval sprintf( '{ package %s::%s; do $name or die $@ || $! }', __PACKAGE__, $gibberish ) or die $@;
}

#-------------------------------------------------------------------

=head2 createEnv (pathInfo)

Called by dispatch() to create the PSGI environment.


=cut

my @psgiVersion = ( 1, 1 );

sub createEnv {
    my ( $self, $pathInfo ) = @_;
    my $r     = $self->session->request;
    my $table = $r->subprocess_env;
    my $ssl   = $table->{HTTP_SSLPROXY} || do {
        my $v = $table->{HTTPS};
        $v && ( $v eq '1' || $v eq 'on' );
    };

    open my $errh, '>', \my $err;

    return {
        %$table,
        'SCRIPT_NAME'       => $self->getUrl,
        'PATH_INFO'         => $pathInfo,
        'psgi.version'      => \@psgiVersion,
        'psgi.url_scheme'   => $ssl ? 'https' : 'http',
        'psgi.input'        => $r,
        'psgi.errors'       => $errh,
        'psgi.multithread'  => 0,
        'psgi.multiprocess' => 1,
        'psgi.run_once'     => 0,
        'psgi.streaming'    => 1,
        'psgi.nonblocking'  => 0,
        'webgui.session'    => $self->session,
        'webgui.asset'      => $self,
        'webgui.cleanup'    => sub {
            close $errh;
            $self->printErr($err) if $err;
        },
    };
} ## end sub createEnv

#-------------------------------------------------------------------

=head2 dispatch ( $fragment )

See the superclass for documentation.  We will do "normal" asset dispatch
(func=blah -> www_blah) if there is no fragment and we have such a function
(www_add, etc), or if calling the PSGI app fails (because we can't compile it,
it throws an exception, or returns an invalid response).

=cut

sub dispatch {
    my ( $self, $fragment ) = @_;
    my $func = $self->session->form->get('func');

    if ( !$fragment && $func && $self->can("www_$func") ) {
        $self->SUPER::dispatch($fragment);
    }

    my $env      = $self->createEnv($fragment);
    my $cleanup  = Scope::Guard->new( $env->{'webgui.cleanup'} );
    my $app      = $self->app || return $self->badApp($env);
    $self->callApp($app, $env, sub { $self->handleResponse(shift) });

    return 'chunked';
} ## end sub dispatch

#-------------------------------------------------------------------

=head2 getContentLastModified ( )

This will always return the current time, since we have no concievable way of
knowing the answer.

=cut

sub getContentLastModified {time}

#-------------------------------------------------------------------

=head2 getName ( )

Called as a class method to determine the name of your asset (see
WebGUI::Asset).  You should override this.

=cut

sub getName {'Untitled PSGI Application'}

#-------------------------------------------------------------------

=head2 handleArray ( $array )

Called by handleBody r when the psgi app returned an arrayref.  By default,
prints each member of the array to session->output in succession.

=cut

sub handleArray {
    my ( $self, $array ) = @_;
    my $out = $self->session->output;
    $out->print($_) for @$array;
}

#-------------------------------------------------------------------

=head2 handleBody ( $body )

Called by handleResponse to deal with the response body.  Its return value is
also returned from handleResponse (and thus dispatch).  By default, we
print the body somehow (or return a writer in the streaming case).

=cut

sub handleBody {
    my ( $self, $body ) = @_;

    if ( !defined $body ) {
        return WebGUI::Asset::Wobject::PSGI::Writer->new($self->session);
    }

    if ( my $path = eval { $body->path } ) {
        return $self->handleFile($body);
    }

    if ( ref $body eq 'ARRAY' ) {
        return $self->handleArray($body);
    }

    if ( eval { $body->can('getline') } ) {
        return $self->handleIo($body);
    }

    $self->session->log->error("Don't know how to handle response $body");
} ## end sub handleBody

#-------------------------------------------------------------------

=head2 handleFile ( $file )

Called by handleBody to deal with real-live file responses.  Our default
behavior is to hook the file onto http->setStreamedFile.

=cut

sub handleFile {
    my ( $self, $file ) = @_;
    $self->session->http->setStreamedFile($file);
}

#-------------------------------------------------------------------

=head2 handleHeaders ( arrayref )

Called by handleResponse to deal with the headers.  Our default behavior is to
basically session->request->headers_out->add() them, with a couple of special
cases, and then call http->sendHeader().

=cut

sub handleHeaders {
    my ( $self, $headers ) = @_;
    my $session = $self->session;
    my $r       = $session->request;
    my $http    = $session->http;
    my $status  = $http->getStatus;
    my $success = $status >= 200 && $status < 300;
    my $hout    = $success ? $r->headers_out : $r->err_headers_out;

    for ( my $i = 0; $i < @$headers; $i += 2 ) {
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
} ## end sub handleHeaders

#-------------------------------------------------------------------

=head2 handleIo ( $io )

Called by handleBody to deal with an objct that response to ->getline.  We
keep calling it (and printing the result) until it returns undef.

=cut

sub handleIo {
    my ( $self, $io ) = @_;
    my $out = $self->session->output;
    while ( defined( my $line = $io->getline ) ) {
        $out->print($line);
    }
}

#-------------------------------------------------------------------

=head2 handleResponse ( $response )

Set status, call handleHeaders and handleBody.  If you want to do something
wholly different with the response, here's the place.

=cut

sub handleResponse {
    my ( $self, $response ) = @_;
    my ( $status, $headers, $body ) = @$response;
    $self->session->http->setStatus( $status, status_message($status) );
    $self->handleHeaders($headers);
    $self->handleBody($body);
}

#-------------------------------------------------------------------

=head2 printErr ( $error )

Called with the contents of the psgi app's error stream by default.  We
normally handle this by doing session->log->error($error).

=cut

sub printErr { $_[0]->session->log->error( $_[1] ) }

1;
