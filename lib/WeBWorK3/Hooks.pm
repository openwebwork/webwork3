package WeBWorK3::Hooks;

use warnings;
use strict;
use feature 'signatures';
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

sub has_permission ($user, $perm) {
	if ($perm->{allowed_users}) {
		return 0 unless $user->{role};
		return grep { $_ eq $user->{role} } @{ $perm->{allowed_users} };
	}
	return 1 unless ($perm->{check_permission} || $perm->{admin_required});
	return ($user && $user->{is_admin}) if $perm->{admin_required};

	return 1;
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

	# most routes use user_id as a parameter, but one uses 'user' instead.
	my $user_id = $c->stash('user_id') // $c->stash('user');

	if ($c->req->url->to_string =~ /\/api/x) {
		# don't consult the permission table if a user is requesting their own information
		my $userRequestingOwnInfo = ($user_id && $user->{user_id} == $user_id) ? 1 : 0;

		if ($userRequestingOwnInfo
			|| has_permission($user, $c->perm_table->{ $c->{stash}{controller} }{ $c->{stash}{action} }))
		{
			return $next->();
		} else {
			$c->render(json => { has_permission => 0, msg => 'permission error' }, status => 403);
		}
	} else {
		$next->();
	}

	return;
};

1;
