
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
use feature 'signatures';
no warnings qw/experimental::signatures/;

use base qw/DBIx::Class::ResultSet DB::Validation/;

use DB::Utils qw/getCourseInfo getUserInfo getSetInfo updateAllFields/;

use Exception::Class qw/DB::Exception::UserSetExists/;

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

sub getAllUserSets ($self, %args) {
	my @user_sets = $self->search({}, { join => [ { 'problem_set' => 'courses' }, { 'course_users' => 'users' } ] });

	return @user_sets if $args{as_result_set};

	return map { $args{merged} ? _mergeUserSet($_) : _getUserSet($_) } @user_sets;
}

=head2 getAllUserSetsForCourse

get all UserSets for a single course

=head3 arguments

=over

=item * C<info>: hash of either C<course_id> or C<course_name>

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

sub getAllUserSetsForCourse ($self, %args) {
	my $course    = $self->rs('Course')->getCourse(info => $args{info}, as_result_set => 1);
	my @user_sets = $self->search(
		{
			'courses.course_id' => $course->course_id
		},
		{
			join => [ { 'problem_set' => 'courses' }, { 'course_users' => 'users' } ]
		}
	);

	return @user_sets if $args{as_result_set};

	return map { $args{merged} ? _mergeUserSet($_) : _getUserSet($_) } @user_sets;
}

=head3 getUserSetForSet

This fetches a collection of user sets for a given Set; that is this is collection
of users within a set.

This results a collection of three different types 1) a result set 2) a collection
of user sets or 3) a collection of merged sets (problem sets with user overrides).
see below on how to specify with arguments.

=head3 arguments

=over

=item * C<info> a hashref specifying information on what type of UserSets
are to be returned.  One must include either the course_id or course_name and either
a C<set_id> or C<set_name>.

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

sub getUserSetsForSet ($self, %args) {
	my $course      = $self->rs('Course')->getCourse(info => $args{info}, as_result_set => 1);
	my $problem_set = $self->rs('ProblemSet')->getProblemSet(info => $args{info}, as_result_set => 1);
	my @user_sets   = $self->search(
		{ 'problem_set.set_id' => $problem_set->set_id },
		{
			join => [ { 'problem_set' => 'courses' }, { 'course_users' => 'users' } ]
		}
	);

	return @user_sets if $args{as_result_set};

	return map { $args{merged} ? _mergeUserSet($_) : _getUserSet($_) } @user_sets;
}

=head3 getUserSetForUser

This fetches a collection of user sets for a given Set; that is this is collection
of sets for a given user.

This results a collection of three different types 1) a result set 2) a collection
of user sets or 3) a collection of merged sets (problem sets with user overrides).
see below on how to specify with arguments.

=head3 arguments

=over

=item * C<info> a hashref specifying information on what type of UserSets
are to be returned.  One must include either the course_id or course_name and either
a C<user_id> or C<username>.

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

sub getUserSetsForUser ($self, %args) {
	my $course      = $self->rs('Course')->getCourse(info => $args{info}, as_result_set => 1);
	my $course_user = $self->rs('User')->getCourseUser(info => $args{info}, as_result_set => 1);
	my @user_sets   = $self->search(
		{
			'course_users.user_id' => $course_user->user_id,
			'courses.course_id'    => $course->course_id
		},
		{
			join => [ { 'problem_set' => 'courses' }, { 'course_users' => 'users' } ]
		}
	);

	return @user_sets if $args{as_result_set};

	return map { $args{merged} ? _mergeUserSet($_) : _getUserSet($_) } @user_sets;
}

=head2 getUserSet

This fetches a single UserSet for a given course, user, and ProblemSet.

This results a one of three different types 1) a result set 2) a UserSet
or 3) a merged set (problem set with user overrides).  See below on how to
specify with arguments.

=head3 arguments

=over

=item * C<info>
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

sub getUserSet ($self, %args) {
	my $problem_set = $self->rs('ProblemSet')->getProblemSet(info => $args{info}, as_result_set => 1);
	my $course_user = $self->rs('User')->getCourseUser(info => $args{info}, as_result_set => 1);

	my $user_set = $problem_set->user_sets->find({
		course_user_id => $course_user->course_user_id,
		set_version    => $args{info}{set_version} // 0
	});

	DB::Exception::UserSetNotInCourse->throw(message => 'The set '
			. $problem_set->set_name
			. ' with set_version '
			. ($args{info}{set_version} // 0)
			. ' is not assigned to '
			. $course_user->users->username
			. ' in the course.')
		unless defined($user_set) || $args{skip_throw};

	return $user_set if $args{as_result_set};

	return $args{merged} ? _mergeUserSet($user_set) : _getUserSet($user_set);
}

=head2 addUserSet

This adds a user set to the database.

The return is one of three different types 1) a result set 2) a UserSet
or 3) a merged sets (problem sets with user overrides).
see below on how to specify with arguments.

=head3 arguments

=over

=item * C<info> a hashref specifying information on what type of UserSets
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

sub addUserSet ($self, %args) {
	my $problem_set = $self->rs('ProblemSet')->getProblemSet(info => $args{params}, as_result_set => 1);
	my $course_user = $self->rs('User')->getCourseUser(info => $args{params}, as_result_set => 1);

	# Filter down to only the relevant keys.
	my %params =
		map { exists $args{params}{$_} ? ($_ => $args{params}{$_}) : () }
		qw/set_dates set_params set_visible set_version/;

	my $user_set = $problem_set->find_related(
		'user_sets',
		{
			course_user_id => $course_user->course_user_id,
			set_version    => $params{set_version} // 0
		}
	);
	DB::Exception::UserSetExists->throw(message => 'The user '
			. $course_user->users->username
			. ' is already assigned to the set '
			. $problem_set->set_name
			. ' with set version'
			. ($params{set_version} // 0))
		if $user_set;

	# Check that fields/dates/parameters are valid & clean %params
	$problem_set->validateOverrides(\%params);

	$params{course_user_id} = $course_user->course_user_id;
	my $new_user_set = $problem_set->add_to_user_sets(\%params);
	foreach ($problem_set->problems->all()) {
		$_->add_to_user_problems({
			user_set_id => $new_user_set->user_set_id,
			seed        => int(rand(10000)),
		});
	}

	return $new_user_set if $args{as_result_set};

	return $args{merged} ? _mergeUserSet($new_user_set) : _getUserSet($new_user_set);
}

=head2 updateUserSet

update a single UserSet for a given course, user, and ProblemSet

=cut

sub updateUserSet ($self, %args) {
	my $user_set = $self->getUserSet(info => $args{info}, as_result_set => 1, skip_throw => 1);

	DB::Exception::UserSetNotInCourse->throw(message => 'The user '
			. $args{info}{username}
			. ' is not assigned to the set '
			. $args{info}{set_name}
			. ' with set version '
			. ($args{info}{set_version} // 0))
		unless defined($user_set);

	# Filter down to only the relevant keys.
	my %filtered =
		map { exists $args{params}{$_} ? ($_ => $args{params}{$_}) : () }
		qw/set_dates set_params set_visible set_version/;

	# merge this update over any existing overrides (e.g. don't lose date overrides when overriding params)
	my %existing_overrides = $user_set->get_inflated_columns;
	my $merged             = updateAllFields(\%existing_overrides, \%filtered);

	# Check that fields/dates/parameters are valid & clean %params
	my $problem_set = $user_set->problem_set;
	$problem_set->validateOverrides($merged);

	my $updated_user_set = $user_set->update($merged);

	return $updated_user_set if $args{as_result_set};

	return $args{merged} ? _mergeUserSet($updated_user_set) : _getUserSet($updated_user_set);
}

=head2 deleteUserSet

delete a single UserSet for a given course, user, and ProblemSet

=cut

sub deleteUserSet ($self, %args) {
	my $user_set = $self->getUserSet(info => $args{info}, as_result_set => 1);

	DB::Exception::UserSetNotInCourse->throw(
		set_name    => $args{info}->{set_name},
		course_name => $args{info}->{course_name},
		username    => $args{info}->{username}
	) unless defined($user_set);

	$user_set->delete;
	# why are we returning anything from this call? success/failure instead?
	return $user_set if $args{as_result_set};
	return $args{merged} ? _mergeUserSet($user_set) : _getUserSet($user_set);
}

=head2 getUserSetVersions

This method returns all versions of user set for a given user for a set in a course.

=cut

sub getUserSetVersions ($self, %args) {
	my $problem_set = $self->rs('ProblemSet')->getProblemSet(info => $args{info}, as_result_set => 1);
	my $course_user = $self->rs('User')->getCourseUser(info => $args{info}, as_result_set => 1);

	my @user_sets = $self->search({
		set_id         => $problem_set->set_id,
		course_user_id => $course_user->course_user_id,
	});

	return @user_sets if $args{as_result_set};

	return map { $args{merged} ? _mergeUserSet($_) : _getUserSet($_) } @user_sets;
}

# The following are private methods used in this module
# This is a small subroutine to shorten access to the db.

sub rs {
	my ($self, $table) = @_;
	return $self->result_source->schema->resultset($table);
}

# This is the UserSet data with some other relevant fields

sub _getUserSet ($user_set) {
	return {
		$user_set->get_inflated_columns,
		course_name => $user_set->problem_set->courses->course_name,
		set_name    => $user_set->problem_set->set_name,
		username    => $user_set->course_users->users->username,
		set_type    => $user_set->problem_set->set_type
	};
}

# This merges the user set data with the problem set information

sub _mergeUserSet ($user_set) {
	# override the user set params and dates
	my $params = updateAllFields($user_set->problem_set->set_params, $user_set->set_params);
	my $dates  = updateAllFields($user_set->problem_set->set_dates,  $user_set->set_dates);

	return {
		$user_set->get_columns,
		set_type    => $user_set->problem_set->set_type,
		set_name    => $user_set->problem_set->set_name,
		set_visible => $user_set->problem_set->set_visible,
		set_dates   => $dates,
		set_params  => $params,
		course_name => $user_set->problem_set->courses->course_name,
		username    => $user_set->course_users->users->username
	};
}

1;
