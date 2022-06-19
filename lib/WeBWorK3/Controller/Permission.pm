package WeBWorK3::Controller::Permission;
use warnings;
use strict;

use Mojo::Base 'Mojolicious::Controller', -signatures;

sub getRoles ($self) {
	my @roles_as_rs = $self->schema->resultset('Role')->search;
	# convert to hashes
	my @roles = map { $_->role_name } @roles_as_rs;
	$self->render(json => \@roles);
	return;
}

1;
