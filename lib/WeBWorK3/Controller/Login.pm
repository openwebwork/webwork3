package WeBWorK3::Controller::Login;
use warnings;
use strict;

use Mojo::Base 'Mojolicious::Controller', -signatures;

sub login ($c) {
	my $params = $c->req->json;
	if ($c->authenticate($params->{username}, $params->{password})) {
		$c->render(json => { logged_in => 1, user => $c->current_user });
	} else {
		$c->render(json => { logged_in => 0, message => "Incorrect username or password." });
	}
	return;
}

sub logout_user ($c) {
	$c->logout;
	$c->session(expires => 1);
	$c->render(json => { logged_in => 0, message => "Successfully logged out." });
	return;
}

1;
