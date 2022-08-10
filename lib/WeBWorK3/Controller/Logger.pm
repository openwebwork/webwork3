package WeBWorK3::Controller::Logger;
use warnings;
use strict;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use Mojo::Home;
use Mojo::Log;
use JSON qw/decode_json/;

my $clientLogFile = Mojo::Log->new(path => Mojo::Home->new->detect->child('logs', 'clientLog.log'));

sub clientLog ($c) {
	my $rawJSON  = $c->req->body;
	my $logEntry = decode_json($rawJSON);
	my $level    = ($logEntry->{level} =~ /(debug|info|warn|error)/) ? $1 : 'fatal';

	# Optionally log information from user cookie...
	for my $cookie (@{ $c->req->cookies }) {
		$c->log->info($cookie->to_string);
	}

	# Write entire json to file in production mode
	$clientLogFile->$level($rawJSON);    # if ($ENV{MOJO_MODE} && $ENV{MOJO_MODE} eq 'production');

	$c->log->$level($logEntry->{message});
	$c->rendered(200);
	return;
}

1;
