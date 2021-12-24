
=head1 DESCRIPTION

This is the functionality of a UserSet in WeBWorK.  This package is based on
C<DBIx::Class::ResultSet>.  The basics are a CRUD for user sets.

=cut

package DB::Schema::ResultSet::UserSet;

use strict;
use warnings;
use feature 'signatures';
no warnings qw(experimental::signatures);

use base 'DBIx::Class::ResultSet';

use DB::Utils qw/getCourseInfo getUserInfo getSetInfo updateAllFields/;
use DB::WithDates;
use DB::WithParams;

use Exception::Class ('DB::Exception::UserSetExists');

=head2 getUserSets

get all UserSet for a given course and either a given user or given set

=head3 input

=over

=item * A hashref containing

=over

=item - Either a course_name or course_id

=item - information on either a set (set_name or set_id) or a user (user_id or username)

=back

=back

=cut

sub getUserSetsForUser ($self, $info, $as_result_set = 0) {
	my $course      = $self->_getCourse($info);
	my $user        = $self->_getUser($info);
	my $course_user = $self->_getCourseUser($info);

	my @user_sets   = $self->search({ course_user_id => $course_user->course_user_id });
	my @user_setids = map { { set_id => $_->set_id }; } @user_sets;

	my @problem_sets = $course->problem_sets->search(\@user_setids);

	my @user_sets_to_return = ();
	for my $i (0 .. $#user_sets) {
		my $params = _mergeUserSet($problem_sets[$i], $user_sets[$i], $user);
		push(@user_sets_to_return, $params);
	}
	return @user_sets_to_return;
}

=head2 getUserSetsForSet

get an array of all user sets for a given problem set (HW, quiz, etc.)

=cut

sub getUserSetsForSet ($self, $set_info, $as_result_set = 0) {
	my $course = $self->_getCourse($set_info);

	my $problem_set = $self->_getProblemSet({
		course_id => $course->course_id,
		%{ getSetInfo($set_info) }
	});

	my @user_sets = $self->search(
		{
			set_id => $problem_set->set_id
		},
		{
			prefetch => { course_users => 'users' }
		}
	);

	my @user_sets_to_return = ();
	for my $i (0 .. $#user_sets) {
		my $params = _mergeUserSet($problem_set, $user_sets[$i], $user_sets[$i]->course_users->users);
		push(@user_sets_to_return, $params);
	}
	return @user_sets_to_return;
}

=head2 getUserSet

get a single UserSet for a given course, user, and ProblemSet

=cut

sub getUserSet ($self, $user_set_info, $as_result_set = 0) {
	my $problem_set = $self->_getProblemSet($user_set_info);
	my $course_user = $self->_getCourseUser($user_set_info);
	my $user        = $course_user->users;

	my $user_set = $self->find(
		{
			'problem_sets.course_id' => $problem_set->course_id,
			'problem_sets.set_id'    => $problem_set->set_id,
			course_user_id           => $course_user->course_user_id,
		},
		{ prefetch => [qw/problem_sets/] }
	);
	return $user_set if $as_result_set;
	return _mergeUserSet($problem_set, $user_set, $user);
}

=head2 addUserSet

add a single UserSet for a given course, user, and ProblemSet

=cut

sub addUserSet ($self, $user_set_info, $user_set_params = {}, $as_result_set = 0) {
	my $problem_set = $self->_getProblemSet($user_set_info);
	my $course_user = $self->_getCourseUser($user_set_info);

	my $user = $self->_course_user_rs->find({ course_user_id => $course_user->course_user_id })->users;

	DB::Exception::UserSetExists->throw(
		username    => $user->username,
		set_name    => $problem_set->set_name,
		course_name => $problem_set->course_id
	) if $self->getUserSet($user_set_info, 1);

	my $params = {
		course_user_id => $course_user->course_user_id,
		set_id         => $problem_set->set_id
	};

	for my $key (keys %$user_set_params) {
		$params->{$key} = $user_set_params->{$key};
	}

	# Make sure the parameters and dates are valid.
	my $new_user_set = $self->new($params);

	$new_user_set->validParams($problem_set->type, 'set_params') if $new_user_set->set_params;
	$new_user_set->validDates($problem_set->type, 'set_dates')
		if $new_user_set->set_dates && scalar(keys %{ $new_user_set->set_dates }) > 0;

	my $user_set = $problem_set->add_to_user_sets($params);

	# Add_to_user_set not getting default values, so get the just added user_set.
	my $s = $self->find({ user_set_id => $user_set->user_set_id });

	return $user_set if $as_result_set;
	return _mergeUserSet($problem_set, $s, $user);
}

=head2 updateUserSet

update a single UserSet for a given course, user, and ProblemSet

=cut

sub updateUserSet ($self, $user_set_info, $user_set_params = {}, $as_result_set = 0) {
	my $user_set = $self->getUserSet($user_set_info, 1);

	DB::Exception::UserSetNotInCourse->throw(
		set_name    => $user_set_info->{set_name},
		course_name => $user_set_info->{course_name},
		username    => $user_set_info->{username}
	) unless defined($user_set);

	my $problem_set = $self->_problem_set_rs->find({ set_id         => $user_set->set_id });
	my $user        = $self->_course_user_rs->find({ course_user_id => $user_set->course_user_id })->users;

	# Make sure the parameters and dates are valid.
	my $new_user_set = $self->new($user_set_params);

	$new_user_set->validParams($problem_set->type, 'set_params') if $new_user_set->set_params;
	$new_user_set->validDates($problem_set->type, 'set_dates')   if $new_user_set->set_dates;

	my $updated_user_set = $user_set->update($user_set_params);

	return $updated_user_set if $as_result_set;
	return _mergeUserSet($problem_set, $updated_user_set, $user);
}

=head2 deleteUserSet

delete a single UserSet for a given course, user, and ProblemSet

=cut

sub deleteUserSet ($self, $user_set_info, $user_set_params = {}, $as_result_set = 0) {
	my $user_set = $self->getUserSet($user_set_info, 1);

	DB::Exception::UserSetNotInCourse->throw(
		set_name    => $user_set_info->{set_name},
		course_name => $user_set_info->{course_name},
		username    => $user_set_info->{username}
	) unless defined($user_set);

	my $problem_set = $self->_getProblemSet($user_set_info);
	my $user        = $self->_getUser($user_set_info);

	$user_set->delete;
	return $user_set if $as_result_set;
	return _mergeUserSet($problem_set, $user_set, $user);
}

# The following are private methods used in this module.

# Return the Course resultset.
sub _course_rs ($self) {
	return $self->result_source->schema->resultset("Course");
}

# Return the ProblemSet resultset.
sub _problem_set_rs ($self) {
	return $self->result_source->schema->resultset("ProblemSet");
}

# Return the User resultset.
sub _user_rs ($self) {
	return $self->result_source->schema->resultset("User");
}

# Return the User resultset.
sub _course_user_rs ($self) {
	return $self->result_source->schema->resultset("CourseUser");
}

# Return the course/set info given the user_set_info is passed in.

sub _getProblemSet ($self, $info) {
	my $set_info = { %{ getCourseInfo($info) }, %{ getSetInfo($info) } };
	return $self->_problem_set_rs->getProblemSet($set_info, 1);
}

# Return the course/set info given the user_set_info is passed in.

sub _getUser ($self, $info) {
	if ($info->{course_user_id}) {
		return $self->_course_user_rs->find({ course_user_id => $info->{course_user_id} })->users;
	}
	my $user_info = { %{ getCourseInfo($info) }, %{ getUserInfo($info) } };
	return $self->_user_rs->getUser($user_info, 1);
}

# Return the course/set info given the user_set_info is passed in.

sub _getCourse ($self, $info) {
	return $self->_course_rs->getCourse(getCourseInfo($info), 1);
}

# Return the course user with the given data.

sub _getCourseUser ($self, $info) {
	if ($info->{course_user_id}) {
		return $self->result_source->schema->resultset("CourseUser")
			->find({ course_user_id => $info->{course_user_id} });
	}

	my $course = $self->_getCourse($info);
	my $user   = $self->_getUser({
		course_id => $course->course_id,
		%{ getUserInfo($info) }
	});
	return $self->result_source->schema->resultset("CourseUser")
		->find({ course_id => $course->course_id, user_id => $user->user_id });
}

# Merge the user set data with the problem set information.

sub _mergeUserSet ($problem_set, $user_set, $user) {
	# Override the user set params
	my $params = updateAllFields($problem_set->set_params, $user_set->set_params);
	#my $dates  = updateAllFields( $problem_set->dates,  $user_set->dates );

	my $user_set_dates = $user_set->set_dates || {};

	# Check if there are dates in the user_set.  If so, use the user_set dates.  Otherwise use the problem_set dates.
	my @date_fields = keys %$user_set_dates;
	my $dates       = (scalar(@date_fields) > 0) ? $user_set_dates : $problem_set->set_dates;

	return {
		$user_set->get_columns,
		set_type    => $problem_set->set_type,
		set_name    => $problem_set->set_name,
		set_visible => $problem_set->set_visible,
		set_dates   => $dates,
		set_params  => $params,
		username    => $user->username
	};
}

1;
