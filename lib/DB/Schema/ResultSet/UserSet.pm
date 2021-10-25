
=head1 DESCRIPTION

This is the functionality of a UserSet in WeBWorK.  This package is based on
C<DBIx::Class::ResultSet>.  The basics are a CRUD for user sets.

=cut

package DB::Schema::ResultSet::UserSet;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

use Try::Tiny;
use Data::Dumper;

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

sub getUserSetsForUser {
	my ($self, $info, $as_result_set) = @_;
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

sub getUserSetsForSet {
	my ($self, $set_info, $as_result_set) = @_;
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

sub getUserSet {
	my ($self, $user_set_info, $as_result_set) = @_;

	my $problem_set = $self->_getProblemSet($user_set_info);
	my $user        = $self->_getUser($user_set_info);
	my $course_user = $self->_getCourseUser($user_set_info);

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

sub addUserSet {
	my ($self, $user_set_info, $user_set_params, $as_result_set) = @_;

	my $problem_set = $self->_getProblemSet($user_set_info);
	my $user        = $self->_getUser($user_set_info);
	my $course_user = $self->_getCourseUser($user_set_info);

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

	## make sure the parameters and dates are valid.
	my $new_user_set = $self->new($params);

	$new_user_set->validParams($problem_set->type) if $new_user_set->params;
	$new_user_set->validDates($problem_set->type)  if $new_user_set->dates;

	my $user_set = $problem_set->add_to_user_sets($params);

	## add_to_user_set not getting default values, so get the just added user_set
	my $s = $self->find({ user_set_id => $user_set->user_set_id });

	return $user_set if $as_result_set;
	return _mergeUserSet($problem_set, $s, $user);
}

=head2 updateUserSet

update a single UserSet for a given course, user, and ProblemSet

=cut

sub updateUserSet {
	my ($self, $user_set_info, $user_set_params, $as_result_set) = @_;

	my $user_set = $self->getUserSet($user_set_info, 1);

	DB::Exception::UserSetNotInCourse->throw(
		set_name    => $user_set_info->{set_name},
		course_name => $user_set_info->{course_name},
		username    => $user_set_info->{username}
	) unless defined($user_set);

	## only allow params and dates to be updated
	for my $field (keys %$user_set_params) {
		my @allowed_fields = grep { $_ eq $field } qw/set_params set_dates/;
		DB::Exception::InvalidParameter->throw(field_names => $field)
			unless scalar(@allowed_fields) == 1;
	}

	my $problem_set = $self->_getProblemSet($user_set_info);
	my $user        = $self->_getUser($user_set_info);

	## make sure the parameters and dates are valid.
	my $new_user_set = $self->new($user_set_params);

	$new_user_set->validParams($problem_set->type,'set_params') if $new_user_set->set_params;
	$new_user_set->validDates($problem_set->type,'set_dates') if $new_user_set->set_dates;

	my $updated_user_set = $user_set->update($user_set_params);

	## update not getting all values, so get the user_set
	my $s = $self->find({ user_set_id => $user_set->user_set_id });

	return $updated_user_set if $as_result_set;
	return _mergeUserSet($problem_set, $s, $user);
}

=head2 deleteUserSet

delete a single UserSet for a given course, user, and ProblemSet

=cut

sub deleteUserSet {
	my ($self, $user_set_info, $user_set_params, $as_result_set) = @_;

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

## the following are private methods used in this module

# return the Course resultset

sub _course_rs {
	return shift->result_source->schema->resultset("Course");
}

# return the ProblemSet resultset
sub _problem_set_rs {
	return shift->result_source->schema->resultset("ProblemSet");
}

# return the User resultset
sub _user_rs {
	return shift->result_source->schema->resultset("User");
}

# return the course/set info given the user_set_info is passed in

sub _getProblemSet {
	my ($self, $info) = @_;
	my $set_info = { %{ getCourseInfo($info) }, %{ getSetInfo($info) } };
	return $self->_problem_set_rs->getProblemSet($set_info, 1);
}

# return the course/set info given the user_set_info is passed in

sub _getUser {
	my ($self, $info) = @_;
	my $user_info = { %{ getCourseInfo($info) }, %{ getUserInfo($info) } };
	return $self->_user_rs->getUser($user_info, 1);
}

# return the course/set info given the user_set_info is passed in

sub _getCourse {
	my ($self, $info) = @_;
	return $self->_course_rs->getCourse(getCourseInfo($info), 1);
}

# return the course user with the given data

sub _getCourseUser {
	my ($self, $info) = @_;
	my $course = $self->_getCourse($info);
	my $user   = $self->_getUser(
		{
			course_id => $course->course_id,
			%{ getUserInfo($info) }
		},
		1
	);
	return $self->result_source->schema->resultset("CourseUser")
		->find({ course_id => $course->course_id, user_id => $user->user_id });
}

# merge the user set data with the problem set information

sub _mergeUserSet {
	my ($problem_set, $user_set, $user) = @_;

	# override the user set params
	my $params = updateAllFields( $problem_set->set_params, $user_set->set_params );
	# my $dates  = updateAllFields( $problem_set->dates,  $user_set->dates );

	my $user_set_dates = $user_set->set_dates || {};

	# check if there are dates in the user_set
	# and use the user_set dates otherwise use the problem_set ones.
	my @date_fields = keys %$user_set_dates;
	my $dates = (scalar(@date_fields) > 0) ? $user_set_dates : $problem_set->set_dates;

	return {
		$user_set->get_columns,
		set_type    => $problem_set->set_type,
		set_name    => $problem_set->set_name,
		set_visible => $problem_set->set_visible,
		set_dates  => $dates,
		set_params => $params,
		username => $user->username
	};
}

1;
