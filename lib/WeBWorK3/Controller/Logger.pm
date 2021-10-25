package WeBWorK3::Controller::Logger;
use warnings;
use strict;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use Mojo::File qw(path);
use Mojo::Log;
use JSON qw(decode_json);

my $path          = path("$ENV{WW3_ROOT}/logs")->make_path->child('clientLog.log');
my $clientLogFile = Mojo::Log->new(path => $path);

sub clientLog ($c) {
	my $rawJSON  = $c->req->body;
	my $logEntry = decode_json($rawJSON);
	my $level    = ($logEntry->{level} =~ /(debug|info|warn|error)/) ? $1 : 'fatal';

	# optionally log information from user cookie...
	for my $cookie (@{ $c->req->cookies }) {
		$c->log->info($cookie->to_string);
	}

	# write entire json to file in production mode
	$clientLogFile->$level($rawJSON);    # if ( $ENV{MOJO_MODE} && $ENV{MOJO_MODE} eq 'production' );

	$c->log->$level($logEntry->{message});
	$c->rendered(200);
	return;
}

1;
