package WeBWorK3::Controller::Permission;
use warnings;
use strict;

use Mojo::Base 'Mojolicious::Controller', -signatures;

sub getRoles ($c) {
	my @roles_as_rs = $c->schema->resultset('Role')->search;
	# convert to hashes
	my @roles = map { $_->role_name } @roles_as_rs;
	$c->render(json => \@roles);
	return;
}

sub getUIRoutePermissions ($c) {
	my @perms       = $c->schema->resultset('UIPermission')->search;
	my @route_perms = map {
		{ $_->get_inflated_columns };
	} @perms;
	$c->render(json => \@route_perms);
	return;
}

# The checkPermission subroutine checks if the passed in user has permission
# to access the route given in the controller/action.
#
# This is done first by
# 1. ensuring that a route exists in the database.
# 2. checking if the user is an admin and if so, allowing them in.
# 3. if the route just needs authentication access, permit the user.
# 4. return false if the route requires admin access and the user is not an admin.
# 5. if the route allows self access return true if the user_id matches the route.
# 6. checking that the user has a role with an allowed permission.
#

sub checkPermission ($c) {
	# seems like $c->current_user doesn't have access to the course_id, so we never
	# get a CourseUser.
	my $user = $c->current_user;

	# The controller/action pair is stored in the $c->match->stack array at the end.
	# See https://docs.mojolicious.org/Mojolicious/Guides/Routing#Under
	my $controller = $c->match->stack->[1]{controller};
	my $action     = $c->match->stack->[1]{action};

	my $perm_db = $c->schema->resultset('DBPermission')->find({
		category => $controller,
		action   => $action
	});

	# The param method usually gets the course_id correctly, if not check the match->stack.
	my $course_id = $c->param('course_id') // $c->match->stack->[1]->{course_id};
	my $user_id   = $c->match->stack->[1]{user_id};

	DB::Exception::RouteWithoutPermission->throw(
		message => "The route with controller $controller and action $action does not have a permission defined")
		unless defined $perm_db;

	my ($permitted, $msg);
	if ($user->{is_admin} || $perm_db->authenticated) {
		$permitted = 1;
	} elsif ($perm_db->admin_required && !$user->{is_admin}) {
		$permitted = undef;
		$msg       = 'This route requires admin privileges.';
	} elsif (!$course_id && $perm_db->allow_self_access && defined($user_id)) {
		# Some routes allow self access, but the course_id is not defined.
		$permitted = $user->{user_id} == $user_id;
	} elsif ($course_id) {
		my $course_user = $c->schema->resultset('User')->getCourseUser(
			info => {
				user_id   => $user->{user_id},
				course_id => $course_id
			},
			merged     => 1,
			skip_throw => 1
		);

		if (!$course_user) {
			$permitted = undef;
			$msg       = 'The user does not belong to the course.';
		} else {
			my $user_role_id = $course_user->{role_id};
			if (!defined($user_role_id)) {
				$permitted = undef;
				$msg       = 'The user does not have a role in the course.';
			} elsif ($perm_db->allow_self_access && $user_id && $user_id == $user->{user_id}) {
				$permitted = 1;
			} else {
				$permitted = grep { $_ == $user_role_id } map { $_->role_id } $perm_db->roles;
				$msg       = 'The user does not have permission for the route' unless $permitted;
			}
		}
	}

	$c->render(json => { has_permission => 0, msg => $msg }, status => 403) unless $permitted;
	return $permitted;
}

1;
