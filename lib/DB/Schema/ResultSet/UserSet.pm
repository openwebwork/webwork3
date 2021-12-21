
=head1 DESCRIPTION

This is the functionality of a UserSet in WeBWorK.  This package is based on
C<DBIx::Class::ResultSet>.  There are two different but related sets of methods:

=over

=item * user sets

These are CRUD methods related to information in the user_set database table,
that is information for a given user that is used to override in the related
problem set.

=item * merged sets

These are getter methods for getting objects/hashes for the merging of a problem set
with the overriding data in a user set.

=back

=cut

package DB::Schema::ResultSet::UserSet;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

use Clone qw/clone/;
use DB::Utils qw/getCourseInfo getUserInfo getSetInfo updateAllFields/;
use DB::WithDates;
use DB::WithParams;

use Exception::Class ('DB::Exception::UserSetExists');

=head2 getAllUserSets

get all UserSets for all courses

=head3 arguments

=over

=item * C<as_result_set>: boolean

If C<as_result_set> is true, then the user sets are returned as a C<ResultSet>.
See C<DBIx::Class::ResultSet> for more information

=item * C<merged>: boolean

This only pertains to if C<as_result_set> is false.

If C<merged> is false, the result is an array of hashrefs of UserSet fields.

If C<merged> is true, the result is an array of hashrefs of Merged User Sets.
That is, a C<ProblemSet> (HWSet, Quiz, ...) with UserSet overrides.

=back

=cut

sub getAllUserSets {
	my ($self, %args) = @_;
	my @user_sets = $self->search(
		{},
		{
			join => [ { 'problem_sets' => 'courses' }, { 'course_users' => 'users' } ]
		}
	);

	return @user_sets if $args{as_result_set};

	my @all_user_sets = ();
	for my $user_set (@user_sets) {
		my $params = $args{merged} ? _mergeUserSet($user_set) : _getUserSet($user_set);
		delete $params->{type};
		push(@all_user_sets, $params);
	}

	return @all_user_sets;
}

=head3 getUserSets

This fetches a collection of user sets.  This could either be 1) a collection
for a given problem set or 2) a collection for a given user (see arguments below)
on how to specify.

This results a collection of three different types 1) a result set 2) a collection
of user sets or 3) a collection of merged sets (problem sets with user overrides).
see below on how to specify with arguments.

=head3 arguments

=over

=item * C<user_set_info> a hashref specifying information on what type of UserSets
are to be returns.  One must include either the course_id or course_name and if the
collection is related to a ProblemSet, the specify either C<set_id> or C<set_name>
otherwise if it is a collection related to a given user then specifiy either
C<user_id> or C<username>

=item * C<as_result_set>: boolean

If C<as_result_set> is true, then the user sets are returned as a C<ResultSet>.
See C<DBIx::Class::ResultSet> for more information

=item * C<merged>: boolean

This only pertains to if C<as_result_set> is false.

If C<merged> is false, the result is an array of hashrefs of UserSet fields.

If C<merged> is true, the result is an array of hashrefs of Merged User Sets.
That is, a C<ProblemSet> (HWSet, Quiz, ...) with UserSet overrides.

=over

=cut

sub getUserSets {
	my ($self, %args) = @_;
	my $course = $self->_getCourse($args{user_set_info});

	my @user_sets;

	if ($args{user_set_info}->{set_id} || $args{user_set_info}->{set_name}) {
		my $problem_set = $self->_getProblemSet($args{user_set_info});
		@user_sets = $self->search(
			{ 'problem_sets.set_id' => $problem_set->set_id },
			{
				join => [ { 'problem_sets' => 'courses' }, { 'course_users' => 'users' } ]
			}
		);

	} elsif ($args{user_set_info}->{user_id} || $args{user_set_info}->{username}) {
		my $user        = $self->_getUser($args{user_set_info});
		my $course_user = $self->_getCourseUser($args{user_set_info});

		@user_sets = $self->search(
			{ 'course_users.user_id' => $user->user_id },
			{
				join => [ { 'problem_sets' => 'courses' }, { 'course_users' => 'users' } ]
			}
		);

	} else {
		# throw an error.
	}

	return @user_sets if $args{as_result_set};

	my @sets = ();
	for my $user_set (@user_sets) {
		my $params = $args{merged} ? _mergeUserSet($user_set) : _getUserSet($user_set);
		delete $params->{type};
		push(@sets, $params);
	}

	return @sets;
}

=head2 getUserSet

This fetches a single UserSet for a given course, user, and ProblemSet.

This results a one of three different types 1) a result set 2) a UserSet
or 3) a merged set (problem set with user overrides).  See below on how to
specify with arguments.

=head3 arguments

=over

=item * C<user_set_info>
a hashref specifying information to fetch the given UserSet.  This hashref must
include:

=over
=item * C<course_id> or C<user_id>
=item * C<user_id> or C<username>
=item * C<set_id> or C<set_name>
=back

=item * C<as_result_set>: boolean

If C<as_result_set> is true, then the user sets are returned as a C<ResultSet>.
See C<DBIx::Class::ResultSet> for more information

=item * C<merged>: boolean

This only pertains to if C<as_result_set> is false.

If C<merged> is false, the result is a hashref of UserSet fields.

If C<merged> is true, the result is hashref of merged user sets.
That is, a C<ProblemSet> (HWSet, Quiz, ...) with UserSet overrides.

=back

=cut

sub getUserSet {
	my ($self, %args) = @_;

	my $problem_set = $self->_getProblemSet($args{user_set_info});
	my $course_user = $self->_getCourseUser($args{user_set_info});

	my $user_set = $self->find(
		{
			'problem_sets.course_id' => $problem_set->course_id,
			'problem_sets.set_id'    => $problem_set->set_id,
			course_user_id           => $course_user->course_user_id,
		},
		{ join => [qw/problem_sets/] }
	);

	DB::Exception::UserSetNotInCourse->throw(message => "The set "
			. $problem_set->set_name
			. " is not assigned to "
			. $course_user->users->username
			. " in the course.")
		unless defined $user_set;

	return $user_set if $args{as_result_set};

	my $params = $args{merged} ? _mergeUserSet($user_set) : _getUserSet($user_set);
	delete $params->{type};
	return $params;
}

=head2 addUserSet

This adds a user set to the database.

The return is one of three different types 1) a result set 2) a UserSet
or 3) a merged sets (problem sets with user overrides).
see below on how to specify with arguments.

=head3 arguments

=over

=item * C<user_set_info> a hashref specifying information on what type of UserSets
are to be returns.  One must include either the course_id or course_name and if the
collection is related to a ProblemSet, the specify either C<set_id> or C<set_name>
otherwise if it is a collection related to a given user then specifiy either
C<user_id> or C<username>

=item * C<user_set_params>
a hashref of parameters for the newly added user set.  See ?? for the specific
parameters.

=item * C<as_result_set>: boolean

If C<as_result_set> is true, then the user sets are returned as a C<ResultSet>.
See C<DBIx::Class::ResultSet> for more information

=item * C<merged>: boolean

This only pertains to if C<as_result_set> is false.

If C<merged> is false, the result is a hashrefs of UserSet fields.

If C<merged> is true, the result is a hashref of  a Merged User Set.
That is, a C<ProblemSet> (HWSet, Quiz, ...) with UserSet overrides.

=back

=cut

sub addUserSet {
	my ($self, %args) = @_;
	my $problem_set = $self->_getProblemSet($args{user_set_info});
	my $course_user = $self->_getCourseUser($args{user_set_info});

	my $user_set = $self->find(
		{
			'problem_sets.course_id' => $problem_set->course_id,
			'problem_sets.set_id'    => $problem_set->set_id,
			course_user_id           => $course_user->course_user_id,
		},
		{ join => [qw/problem_sets/] }
	);

	DB::Exception::UserSetExists->throw(message => "The user "
			. $course_user->users->username
			. " is already assigned to the set "
			. $problem_set->set_name)
		if $user_set;

	# the hashref of parameters is a mixture of passed in parameters and defaults

	my $params = $args{user_set_params} ? clone($args{user_set_params}) : {};
	$params->{course_user_id} = $course_user->course_user_id;
	$params->{set_id}         = $problem_set->set_id;
	$params->{type}           = $problem_set->type;
	$params->{set_params}     = {} unless defined($params->{set_params});
	$params->{set_version}    = 1  unless defined($params->{set_version});
	my $original_dates = $params->{set_dates} // {};

	# make sure the parameters and dates are valid.
	# to make sure the dates are valid, make a merged date hash to check
	$params->{set_dates} = updateAllFields($problem_set->set_dates, $params->{set_dates} // {});

	my $new_user_set = $self->new($params);
	$new_user_set->validParams('set_params') if $new_user_set->set_params;
	$new_user_set->validDates('set_dates')
		if $new_user_set->set_dates && scalar(keys %{ $new_user_set->set_dates }) > 0;

	# if the dates and params are valid reset the set_dates to only those passed in:
	$params->{set_dates} = $original_dates;

	$new_user_set = $problem_set->add_to_user_sets($params);

	return $new_user_set if $args{as_result_set};

	my $new_params = $args{merged} ? _mergeUserSet($new_user_set) : _getUserSet($new_user_set);
	delete $new_params->{type};
	return $new_params;
}

=head2 updateUserSet

update a single UserSet for a given course, user, and ProblemSet

=cut

sub updateUserSet {
	my ($self, %args) = @_;
	my $user_set = $self->getUserSet(user_set_info => $args{user_set_info}, as_result_set => 1);

	DB::Exception::UserSetNotInCourse->throw(
		set_name    => $args{user_set_info}->{set_name},
		course_name => $args{user_set_info}->{course_name},
		username    => $args{user_set_info}->{username}
	) unless defined($user_set);

	my $params = clone $args{user_set_params};

	$params->{course_user_id} = $user_set->course_users->course_user_id;
	$params->{set_id}         = $user_set->problem_sets->set_id;
	$params->{type}           = $user_set->problem_sets->type;
	$params->{set_version}    = 1 unless defined($params->{set_version});

	# create a hash of the dates from the database overriden with any passed in.
	my $dates = updateAllFields($user_set->set_dates, $params->{set_dates});

	# then make sure the dates are valid by making a merged date hash to check
	$params->{set_dates} = updateAllFields($user_set->problem_sets->set_dates, $params->{set_dates} // {});

	# create a hash of the set_params from the database overriden with any passed in
	$params->{set_params} = updateAllFields($user_set->set_params, $params->{set_params});

	# validate all fields
	my $new_user_set = $self->new($params);
	$new_user_set->validParams('set_params') if $new_user_set->set_params;
	$new_user_set->validDates('set_dates')
		if $new_user_set->set_dates && scalar(keys %{ $new_user_set->set_dates }) > 0;

	# if the dates are valid reset the set_dates to not include those from the problem set
	$params->{set_dates} = $dates;

	my $updated_user_set = $user_set->update($params);

	return $updated_user_set if $args{as_result_set};

	my $new_params = $args{merged} ? _mergeUserSet($updated_user_set) : _getUserSet($updated_user_set);
	delete $new_params->{type};
	return $new_params;
}

=head2 deleteUserSet

delete a single UserSet for a given course, user, and ProblemSet

=cut

sub deleteUserSet {
	my ($self, %args) = @_;
	my $user_set = $self->getUserSet(user_set_info => $args{user_set_info}, as_result_set => 1);

	DB::Exception::UserSetNotInCourse->throw(
		set_name    => $args{user_set_info}->{set_name},
		course_name => $args{user_set_info}->{course_name},
		username    => $args{user_set_info}->{username}
	) unless defined($user_set);

	$user_set->delete;
	return $user_set if $args{as_result_set};
	my $new_params = $args{merged} ? _mergeUserSet($user_set) : _getUserSet($user_set);
	delete $new_params->{type};
	return $new_params;
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

# return the User resultset
sub _course_user_rs {
	return shift->result_source->schema->resultset("CourseUser");
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
	if ($info->{course_user_id}) {
		return $self->_course_user_rs->find({ course_user_id => $info->{course_user_id} })->users;
	}
	my $user_info = { %{ getCourseInfo($info) }, %{ getUserInfo($info) } };
	return $self->_user_rs->getUser($user_info, 1);
}

# return the course/set info given the user_set_info is passed in

sub _getCourse {
	my ($self, $info) = @_;
	return $self->_course_rs->getCourse(getCourseInfo($info), 1);
}

# return the course user with the given data
#
# $info is a hashref with
# * course_user_id or
# * course_id or course_name AND user_id or username

sub _getCourseUser {
	my ($self, $info) = @_;

	if ($info->{course_user_id}) {
		return $self->result_source->schema->resultset("CourseUser")
			->find({ course_user_id => $info->{course_user_id} });
	}

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

# get the user set data with some additional fields

sub _getUserSet {
	my $user_set = shift;
	return {
		$user_set->get_inflated_columns,
		course_name => $user_set->problem_sets->courses->course_name,
		set_name    => $user_set->problem_sets->set_name,
		username    => $user_set->course_users->users->username,
		set_type    => $user_set->set_type
	};
}

# merge the user set data with the problem set information

sub _mergeUserSet {
	my $user_set = shift;

	# override the user set params and dates
	my $params = updateAllFields($user_set->problem_sets->set_params, $user_set->set_params);
	my $dates  = updateAllFields($user_set->problem_sets->set_dates,  $user_set->set_dates);

	return {
		$user_set->get_columns,
		set_type    => $user_set->problem_sets->set_type,
		set_name    => $user_set->problem_sets->set_name,
		set_visible => $user_set->problem_sets->set_visible,
		set_dates   => $dates,
		set_params  => $params,
		course_name => $user_set->problem_sets->courses->course_name,
		username    => $user_set->course_users->users->username
	};
}

1;
