package WeBWorK3::Controller::User;
use Mojo::Base 'Mojolicious::Controller', -signatures;

use Try::Tiny;

sub getGlobalUsers ($c) {
	my @global_users = $c->schema->resultset('User')->getAllGlobalUsers;
	$c->render(json => \@global_users);
	return;
}

# Passing the username into the getGlobalUser results in a problem with permssions.  This route
# should be used to pass in the username.
sub checkGlobalUser ($c) {
	try {
		my $user = $c->schema->resultset('User')->getGlobalUser(info => { username => $c->param('username') });
		$c->render(json => $user);
		return;
	} catch {
		$c->render(json => {}) if ref($_) eq 'DB::Exception::UserNotFound';
	};
	return;
}

sub getGlobalUser ($c) {
	my $user =
		$c->param('user_id') =~ /^\d+$/
		? $c->schema->resultset('User')->getGlobalUser(info => { user_id  => int($c->param('user_id')) })
		: $c->schema->resultset('User')->getGlobalUser(info => { username => $c->param('user_id') });
	$c->render(json => $user);
	return;
}

sub updateGlobalUser ($c) {
	my $user = $c->schema->resultset('User')->updateGlobalUser(
		info   => { user_id => int($c->param('user_id')) },
		params => $c->req->json
	);
	$c->render(json => $user);
	return;
}

sub addGlobalUser ($c) {
	my $user = $c->schema->resultset('User')->addGlobalUser(params => $c->req->json);
	$c->render(json => $user);
	return;
}

sub deleteGlobalUser ($c) {
	my $user = $c->schema->resultset('User')->deleteGlobalUser(info => { user_id => int($c->param('user_id')) });
	$c->render(json => $user);
	return;
}

# This gets all global users for a given course
sub getGlobalCourseUsers ($c) {
	my @users = $c->schema->resultset('User')->getGlobalCourseUsers(
		info => {
			course_id => int($c->param('course_id'))
		}
	);
	$c->render(json => \@users);
	return;
}

# The following are needed for handling global users from instructors in a course

sub getGlobalUsersFromCourse   ($c) { $c->getGlobalUsers;   return }
sub getGlobalUserFromCourse    ($c) { $c->getGlobalUser;    return }
sub getUserCoursesFromCourse   ($c) { $c->getCourseUsers;   return }
sub addGlobalUserFromCourse    ($c) { $c->addGlobalUser;    return }
sub updateGlobalUserFromCourse ($c) { $c->updateGlobalUser; return }
sub deleteGlobalUserFromCourse ($c) { $c->deleteGlobalUser; return }

# The following subs are related to users within a given course.

sub getMergedCourseUsers ($c) {
	my @course_users =
		$c->schema->resultset('User')
		->getCourseUsers(info => { course_id => int($c->param('course_id')) }, merged => 1);
	$c->render(json => \@course_users);
	return;
}

sub getCourseUsers ($c) {
	my @course_users =
		$c->schema->resultset('User')->getCourseUsers(info => { course_id => int($c->param('course_id')) });
	$c->render(json => \@course_users);
	return;
}

sub getCourseUser ($c) {
	my $course_user = $c->schema->resultset('User')->getCourseUser(
		info => {
			course_id => int($c->param('course_id')),
			user_id   => int($c->param('user_id'))
		}
	);
	$c->render(json => $course_user);
	return;
}

sub addCourseUser ($c) {
	my $info = { course_id => int($c->param('course_id')) };
	$info->{username} = $c->req->json->{username}     if defined($c->req->json->{username});
	$info->{user_id}  = int($c->req->json->{user_id}) if defined($c->req->json->{user_id});

	my $course_user = $c->schema->resultset('User')->addCourseUser(
		info   => $info,
		params => $c->req->json
	);
	$c->render(json => $course_user);
	return;
}

sub updateCourseUser ($c) {
	my $course_user = $c->schema->resultset('User')->updateCourseUser(
		info => {
			course_id => int($c->param('course_id')),
			user_id   => int($c->param('user_id'))
		},
		params => $c->req->json
	);
	$c->render(json => $course_user);
	return;
}

sub deleteCourseUser ($c) {
	my $course_user = $c->schema->resultset('User')->deleteCourseUser(
		info => {
			course_id => int($c->param('course_id')),
			user_id   => int($c->param('user_id'))
		}
	);
	$c->render(json => $course_user);
	return;
}

sub getUserCourses ($c) {
	my @user_courses =
		$c->schema->resultset('Course')->getUserCourses(info => { user_id => $c->param('user_id') });
	$c->render(json => \@user_courses);
	return;
}

1;
