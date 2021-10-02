package WeBWorK3::Controller::User;
use Mojo::Base 'Mojolicious::Controller', -signatures;

use Data::Dump qw/dd/;

sub getGlobalUsers {
	my $self = shift;
	my @global_users =  $self->schema->resultset("User")->getAllGlobalUsers;
	$self->render(json => \@global_users);
	return;
}

sub getGlobalUser {
	my $self = shift;
	my $user = $self->param("user") =~ /^\d+$/ ?
		$self->schema->resultset("User")->getGlobalUser( { user_id => int( $self->param("user") )} ) :
		$self->schema->resultset("User")->getGlobalUser( { username => $self->param("user") } );
	$self->render(json => $user);
	return;
}

sub updateGlobalUser {
	my $self = shift;
	my $user = $self->schema->resultset("User")->updateGlobalUser(
		{ user_id => int( $self->param("user_id") )},
		$self->req->json );
	$self->render(json => $user);
	return;
}

sub addGlobalUser {
	my $self = shift;
	my $user = $self->schema->resultset("User")->addGlobalUser($self->req->json );
	$self->render(json => $user);
	return;
}

sub deleteGlobalUser {
	my $self = shift;
	my $user = $self->schema->resultset("User")->deleteGlobalUser({user_id => int($self->param("user_id"))});
	$self->render(json => $user);
	return;
}

## the following subs are related to users within a given course.

sub getMergedCourseUsers ($c) {
	my @course_users = $c->schema->resultset("User")->getMergedCourseUsers(
		{course_id => int($c->param("course_id"))});
	$c->render(json => \@course_users);
	return;
}

sub getCourseUsers {
	my $self = shift;
	my @course_users = $self->schema->resultset("User")->getCourseUsers(
		{course_id => int($self->param("course_id"))});
	$self->render(json => \@course_users);
	return;
}

sub getCourseUser {
	my $self = shift;
	my $course_user = $self->schema->resultset("User")->getCourseUser(
		{
			course_id => int($self->param("course_id")),
			user_id => int($self->param("user_id"))
		}
	);
	$self->render(json => $course_user);
	return;
}

sub addCourseUser {
	my $self = shift;
	my $params = $self->req->json;
	$params->{course_id} = $self->param("course_id");
	my $course_user = $self->schema->resultset("User")->addCourseUser($params);
	$self->render(json => $course_user);
	return;
}

sub updateCourseUser {
	my $self = shift;
	my $course_user = $self->schema->resultset("User")->updateCourseUser(
		{
			course_id => int($self->param("course_id")),
			user_id => int($self->param("user_id"))
		}, $self->req->json);
	$self->render(json => $course_user);
	return;
}

sub deleteCourseUser {
	my $self = shift;
	my $course_user = $self->schema->resultset("User")->deleteCourseUser(
		{
			course_id => int($self->param("course_id")),
			user_id => int($self->param("user_id"))
		});
	$self->render(json => $course_user);
	return;
}

sub getUserCourses {
	my $self = shift;
	my @user_courses = $self->schema->resultset("Course")
		->getUserCourses({user_id => $self->param('user_id')});
	$self->render(json => \@user_courses);
	return;
}

1;
