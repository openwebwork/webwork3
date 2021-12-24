package WeBWorK3::Controller::User;
use Mojo::Base 'Mojolicious::Controller', -signatures;

sub getGlobalUsers {
	my $self         = shift;
	my @global_users = $self->schema->resultset("User")->getAllGlobalUsers;
	$self->render(json => \@global_users);
	return;
}

sub getGlobalUser {
	my $self = shift;
	my $user =
		$self->param("user") =~ /^\d+$/
		? $self->schema->resultset("User")->getGlobalUser(info => { user_id  => int($self->param("user")) })
		: $self->schema->resultset("User")->getGlobalUser(info => { username => $self->param("user") });
	$self->render(json => $user);
	return;
}

sub updateGlobalUser {
	my $self = shift;
	my $user = $self->schema->resultset("User")
		->updateGlobalUser(info => { user_id => int($self->param("user_id")) }, params => $self->req->json);
	$self->render(json => $user);
	return;
}

sub addGlobalUser {
	my $self = shift;
	my $user = $self->schema->resultset("User")->addGlobalUser(params => $self->req->json);
	$self->render(json => $user);
	return;
}

sub deleteGlobalUser {
	my $self = shift;
	my $user = $self->schema->resultset("User")->deleteGlobalUser(info => { user_id => int($self->param("user_id")) });
	$self->render(json => $user);
	return;
}

## the following subs are related to users within a given course.

sub getMergedCourseUsers ($c) {
	my @course_users = $c->schema->resultset("User")
		->getCourseUsers(info => { course_id => int($c->param("course_id")) }, merged => 1);
	$c->render(json => \@course_users);
	return;
}

sub getCourseUsers {
	my $self = shift;

	my @course_users =
		$self->schema->resultset("User")->getCourseUsers(info => { course_id => int($self->param("course_id")) });
	$self->render(json => \@course_users);
	return;
}

sub getCourseUser {
	my $self        = shift;
	my $course_user = $self->schema->resultset("User")->getCourseUser(
		info => {
			course_id => int($self->param("course_id")),
			user_id   => int($self->param("user_id"))
		}
	);
	$self->render(json => $course_user);
	return;
}

sub addCourseUser {
	my $self = shift;

	my $info = { course_id => int($self->param("course_id")) };
	$info->{username} = $self->req->json->{username}     if $self->req->json->{username};
	$info->{user_id}  = int($self->req->json->{user_id}) if $self->req->json->{user_id};

	my $course_user = $self->schema->resultset("User")->addCourseUser(
		info   => $info,
		params => $self->req->json
	);
	$self->render(json => $course_user);
	return;
}

sub updateCourseUser {
	my $self        = shift;
	my $course_user = $self->schema->resultset("User")->updateCourseUser(
		info => {
			course_id => int($self->param("course_id")),
			user_id   => int($self->param("user_id"))
		},
		params => $self->req->json
	);
	$self->render(json => $course_user);
	return;
}

sub deleteCourseUser {
	my $self        = shift;
	my $course_user = $self->schema->resultset("User")->deleteCourseUser(
		info => {
			course_id => int($self->param("course_id")),
			user_id   => int($self->param("user_id"))
		}
	);
	$self->render(json => $course_user);
	return;
}

sub getUserCourses {
	my $self = shift;
	my @user_courses =
		$self->schema->resultset("Course")->getUserCourses(info => { user_id => $self->param('user_id') });
	$self->render(json => \@user_courses);
	return;
}

1;
