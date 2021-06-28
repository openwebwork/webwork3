package webwork3::Controller::Login;
use Mojo::Base 'Mojolicious::Controller', -signatures;

use Data::Dump qw/dd/;

# This action will render a template
sub login_page { shift->render();}
sub login_help { shift->render();}

sub check_login {
	my $self = shift;
	if ($self->authenticate($self->req->param("email"),$self->req->param("password"))) {
		## redirect
		dd "logged in ok";
		$self->redirect_to("/users/start");
	} else {
		$self->flash(msg => "Your login/password information is not correct.");
		$self->redirect_to('login');
	}
}

## route to show all courses for a user

sub user_courses {
	my $self = shift;
	my $user = $self->schema->resultset("User")->getGlobalUser({user_id => $self->current_user});
	my $course_rs = $self->schema->resultset("Course");
	my @user_courses = $course_rs->getUserCourses({user_id => $self->current_user});
  # Render template "example/welcome.html.ep" with message
  $self->render(user => $user, user_courses => \@user_courses);
}

sub logout_page {
	my $self = shift;
	$self->logout;
	$self->render();
}

#
# TODO: handle post parameters as well.
#

sub login {
	my $self = shift;
	my $params = $self->req->json;
	# dd $params;
	if ($self->authenticate($params->{email},$params->{password})) {
		## redirect
		$self->render(json=>{logged_in => 1, user => $self->current_user});
	} else {
		$self->render(json=>{logged_in => 0, msg => "Your login information was incorrect"});
	}
}

sub logout_user {
	my $self = shift;
	$self->logout;
	$self->render(json => {logged_in => 0, msg => "Logout is successful"});
}

1;
