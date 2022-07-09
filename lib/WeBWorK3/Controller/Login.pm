package WeBWorK3::Controller::Login;
use warnings;
use strict;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use Mojo::JSON qw/true false/;

sub login ($c) {
	my $params = $c->req->json;
	if ($c->authenticate($params->{username}, $params->{password})) {
		$c->render(json => { logged_in => true, user => $c->current_user });
	} else {
		$c->render(json => { logged_in => false, message => 'Incorrect username or password.' });
	}
	return;
}

sub logout_user ($c) {
	$c->logout;
	$c->session(expires => 1);
	$c->render(json => { logged_in => false, message => 'Successfully logged out.' });
	return;
}

1;
