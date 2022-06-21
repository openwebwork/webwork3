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

sub getUIRoutePermissions ($self) {
	my @perms       = $self->schema->resultset('UIPermission')->search;
	my @route_perms = map {
		{ $_->get_inflated_columns };
	} @perms;
	$self->render(json => \@route_perms);
	return;
}

1;
