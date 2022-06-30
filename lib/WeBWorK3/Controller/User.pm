package WeBWorK3::Controller::User;
use Mojo::Base 'Mojolicious::Controller', -signatures;

use Try::Tiny;

sub getGlobalUsers ($self) {
	my @global_users = $self->schema->resultset('User')->getAllGlobalUsers;
	$self->render(json => \@global_users);
	return;
}

sub getGlobalUser ($self) {
	my $user =
		$self->param('user_id') =~ /^\d+$/
		? $self->schema->resultset('User')->getGlobalUser(info => { user_id  => int($self->param('user_id')) })
		: $self->schema->resultset('User')->getGlobalUser(info => { username => $self->param('user_id') });
	$self->render(json => $user);
	return;
}

# Passing the username into the getGlobalUser results in a problem with permssions.  This route
# should be used to pass in the username.
sub checkGlobalUser ($self) {
	try {
		my $user = $self->schema->resultset('User')->getGlobalUser(info => { username => $self->param('username') });
		$self->render(json => $user);
		return;
	} catch {
		$self->render(json => {}) if ref($_) eq 'DB::Exception::UserNotFound';
	};
	return;
}

sub updateGlobalUser ($self) {
	my $user = $self->schema->resultset('User')->updateGlobalUser(
		info   => { user_id => int($self->param('user_id')) },
		params => $self->req->json
	);
	$self->render(json => $user);
	return;
}

sub addGlobalUser ($self) {
	my $user = $self->schema->resultset('User')->addGlobalUser(params => $self->req->json);
	$self->render(json => $user);
	return;
}

sub deleteGlobalUser ($self) {
	my $user = $self->schema->resultset('User')->deleteGlobalUser(info => { user_id => int($self->param('user_id')) });
	$self->render(json => $user);
	return;
}

# This gets all global users for a given course
sub getGlobalCourseUsers ($self) {
	my @users = $self->schema->resultset('User')->getGlobalCourseUsers(
		info => {
			course_id => int($self->param('course_id'))
		}
	);
	$self->render(json => \@users);
	return;
}

# The following subs are related to users within a given course.

sub getMergedCourseUsers ($self) {
	my @course_users =
		$self->schema->resultset('User')
		->getCourseUsers(info => { course_id => int($self->param('course_id')) }, merged => 1);
	$self->render(json => \@course_users);
	return;
}

sub getCourseUsers ($self) {
	my @course_users =
		$self->schema->resultset('User')->getCourseUsers(info => { course_id => int($self->param('course_id')) });
	$self->render(json => \@course_users);
	return;
}

sub getCourseUser ($self) {
	my $course_user = $self->schema->resultset('User')->getCourseUser(
		info => {
			course_id => int($self->param('course_id')),
			user_id   => int($self->param('user_id'))
		}
	);
	$self->render(json => $course_user);
	return;
}
use Data::Dumper;
sub addCourseUser ($self) {
	print Dumper $self->req->json;
	my $info = { course_id => int($self->param('course_id')) };
	$info->{username} = $self->req->json->{username}     if defined($self->req->json->{username});
	$info->{user_id}  = int($self->req->json->{user_id}) if defined($self->req->json->{user_id});

	print Dumper  $info;
	my $course_user = $self->schema->resultset('User')->addCourseUser(
		info   => $info,
		params => $self->req->json
	);
	$self->render(json => $course_user);
	return;
}

sub updateCourseUser ($self) {
	my $course_user = $self->schema->resultset('User')->updateCourseUser(
		info => {
			course_id => int($self->param('course_id')),
			user_id   => int($self->param('user_id'))
		},
		params => $self->req->json
	);
	$self->render(json => $course_user);
	return;
}

sub deleteCourseUser ($self) {
	my $course_user = $self->schema->resultset('User')->deleteCourseUser(
		info => {
			course_id => int($self->param('course_id')),
			user_id   => int($self->param('user_id'))
		}
	);
	$self->render(json => $course_user);
	return;
}

sub getUserCourses ($self) {
	my @user_courses =
		$self->schema->resultset('Course')->getUserCourses(info => { user_id => $self->param('user_id') });
	$self->render(json => \@user_courses);
	return;
}

1;
