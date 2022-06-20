package WeBWorK3::Hooks;

use warnings;
use strict;
use feature 'signatures';
use feature 'say';
no warnings qw(experimental::signatures);

use Try::Tiny;

our $VERSION = '2.99';

our $exception_handler = sub ($next, $c) {
	# Only test requests that start with '/api'.
	if ($c->req->url->to_string =~ /\/api/x) {
		try {
			$next->();
		} catch {
			my $output = { exception => ref($_) };
			$output->{message} = $_->message
				if (ref($_) && (ref($_) eq 'Mojo::Exception' || ref($_) =~ /^DB::Exception/x));
			$output->{message} = $_ if ($_ && ref($_) eq 'DBIx::Class::Exception');
			$c->log->error($output->{message});
			$c->render(json => $output, status => 500);
		};
	} else {
		$next->();
	}
};

# The has_permission subroutine checks if the passed in user has permission
# to access the route given in the controller/action.
#
# This is done first by
# 1. ensuring that a route exists in the database.
# 2. checking if the user is an admin and if so, allowing them in.
# 3. checking that the user has a role with an allowed permission.
#

sub has_permission ($c, $user) {
	my $perm_db = $c->schema->resultset('DBPermission')->find({
		category =>  $c->{stash}{controller},
		action =>  $c->{stash}{action}
	});
  print $c->{stash}{controller} . "\n";
	DB::Exception::RouteWithoutPermission->throw(
		message => "The route with controller $c->{stash}{controller} and action $c->{stash}{action} does not have a permission defined"
	) unless defined $perm_db;
	return 1 if $user->{is_admin};

	my $allowed_roles = $perm_db->allowed_roles;

	my @tmp =  grep { $_ eq $user->{role} } @{ $allowed_roles };

	if ($allowed_roles) {
		return 1 if scalar(@$allowed_roles) == 1 && $allowed_roles->[0] eq '*';
		return grep { $_ eq $user->{role} } @{ $allowed_roles };
	}
	return $user && $user->{is_admin};
}

# Check permission for /api routes
our $check_permission = sub ($next, $c, $action, $) {
	return $next->() if $c->req->url->to_string =~ m!/api/log(?:in|out)$!;

	if (!$c->is_user_authenticated) {
		$c->render(json => { has_permission => 0, msg => 'permission error' }, status => 401);
		return;
	}

	my $user = $c->current_user;

	if (!$user->{is_admin} && $c->stash('course_id')) {
		my $user_obj =
			$c->schema->resultset('User')->getGlobalUser(info => { user_id => $user->{user_id} }, as_result_set => 1);
		my $course_user = $user_obj->course_users->find({ course_id => $c->stash('course_id') });

		if (!$course_user) {
			# non-admins can't ask about a course that they don't belong to
			$c->render(json => { has_permission => 0, msg => 'permission error' }, status => 406);
			return;
		}

		$user = { %$user, $course_user->get_inflated_columns };
	}

	if ($c->req->url->to_string =~ /\/api/x) {
		# don't consult the permission table if a user is requesting their own information
		my $userRequestingOwnInfo = ($c->stash('user_id') && $user->{user_id} == $c->stash('user_id')) ? 1 : 0;

		if ($userRequestingOwnInfo || has_permission($c, $user))
		{
			return $next->();
		} else {
			$c->render(json => { has_permission => 0, msg => 'permission error' }, status => 403);
		}
	} else {
		return $next->();
	}

	return;
};

1;
