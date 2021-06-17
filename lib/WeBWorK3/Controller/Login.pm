package webwork3::Controller::Login;
use Mojo::Base 'Mojolicious::Controller', -signatures;

use Data::Dump qw/dd/;

# This action will render a template
sub login_page { shift->render();}

sub check_login {
	my $self = shift;
	if ($self->authenticate($self->req->param("email"),$self->req->param("password"))) {
		## redirect
		dd "in check_login";
		my $user_id = $self->current_user; 
		$self->redirect_to("/users/$user_id");
	} else {
		$self->flash(msg => "Your login/password information is not correct.");
		$self->redirect_to('login');
	}
}

## route to show all courses for a user

sub user_courses {
	my $self = shift; 
	my $user = $self->schema->resultset("User")->getGlobalUser({user_id => $self->param("user_id")});
	dd $user; 
	my $course_rs = $self->schema->resultset("Course");
	my @user_courses = $course_rs->getUserCourses({user_id => $self->param("user_id")});
  # Render template "example/welcome.html.ep" with message
  $self->render(user => $user, user_courses => \@user_courses);
}

1;
