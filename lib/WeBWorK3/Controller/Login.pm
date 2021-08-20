package WeBWorK3::Controller::Login;
use warnings;
use strict;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Data::Dump qw/dd/;

# This action will render a template
sub login_page { shift->render(); return;}
sub login_help { shift->render(); return;}

sub check_login {
	my $self = shift;
	if ($self->authenticate($self->req->param("username"), $self->req->param("password"))) {
		## redirect
		$self->redirect_to("/users/start");
	} else {
		$self->flash(msg => "Incorrect username or password.");
		$self->redirect_to('login');
	}
	return;
}

## route to show all courses for a user

sub user_courses {
	my $self = shift;
	my @user_courses = $self->schema->resultset("Course")
		->getUserCourses({user_id => $self->current_user->{user_id}});
	# Render template "example/welcome.html.ep" with message
	$self->render(user => $self->current_user, user_courses => \@user_courses);
	return;
}

sub logout_page {
	my $self = shift;
	$self->logout;
	$self->render();
	return;
}

#
# TODO: handle post parameters as well.
#

sub login {
	my $self = shift;
	my $params = $self->req->json;
	# dd $params;
	if ($self->authenticate($params->{username}, $params->{password})) {
		## redirect
		$self->render(json=>{logged_in => 1, user => $self->current_user});
	} else {
		$self->render(json=>{logged_in => 0, message => "Incorrect username or password."});
	}
	return;
}

sub logout_user {
	my $self = shift;
	$self->logout;
	$self->render(json => {logged_in => 0, message => "Successfully logged out."});
	return;
}

1;
