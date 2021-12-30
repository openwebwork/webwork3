package DB::Schema::ResultSet::UserProblem;
use strict;
use warnings;
use feature 'signatures';
no warnings qw(experimental::signatures);

use Clone qw/clone/;
use base 'DBIx::Class::ResultSet';

use DB::Utils qw/getCourseInfo getSetInfo getProblemInfo getUserInfo updateAllFields/;

use Clone qw/clone/;

use Exception::Class (
	'DB::Exception::UserProblemExists',
	'DB::Exception::UserProblemNotFound',
	'DB::Exception::ProblemNotFound'
);

=head1 DESCRIPTION

This is the functionality of a UserProblem in WeBWorK.  This package is based on
C<DBIx::Class::ResultSet>.  The basics are a CRUD for a UserProblem.

=head2 getAllUserProblems

This gets an array of all UserProblems stored in the database in the C<user_problems> table.

=head3 input

A hash with the following fields:

=over

=item - C<as_result_set>, a boolean if the return is to be a result_set

=item - C<merged>, a boolean if the return is a merged set (UserProblem with Problem)
or just a UserProblem

=back

=head3 output

An array of user problems as a C<DBIx::Class::ResultSet::UserProblem> object
if C<as_result_set> is true.  Otherwise an array of hash_ref of the fields.
See <DB::Schema::Result::User::Problem> for information on the fields.  If C<merged>
is true, the return is a merged hashref.

=cut

sub getAllUserProblems ($self, %args) {
	my @user_problems = $self->search({});

	return @user_problems if $args{as_result_set};

	my @all_user_problems = ();
	for my $user_problem (@user_problems) {
		my $params = $args{merged} ? _mergeUserProblem($user_problem) : _getUserProblem($user_problem);
		push(@all_user_problems, $params);
	}

	return @all_user_problems;
}

=head1 getUserProblems

Get all user problems (or merged user problems) for one course

=head3 input

A hash of input values.

=over

=item * C<info>, either a course name or course_id.

For example, C<{ course_name => 'Precalculus'}> or C<{course_id => 3}>

=item * C<merged>, a boolean on whether to return a merged user or course user

=item * C<as_result_set>, a boolean.  If true this an object of type
C<DBIx::Class::ResultSet::UserProblem>
if false, a hashrefs of a User Problem or merged User Problem with a Problem.

=back

=head3 output

An array of a hashref of a user problem or merged user problem
or an arrayref of C<DBIx::Class::ResultSet::UserProblem>

=cut

sub getUserProblems ($self, %args) {
	my $course        = $self->rs("Course")->getCourse(info => $args{info}, as_result_set => 1);
	my @user_problems = $self->search(
		{
			'courses.course_id' => $course->course_id
		},
		{
			join => { problems => { problem_set => 'courses' } }
		}
	);

	return @user_problems if $args{as_result_set};

	my @user_problems_to_return = ();
	for my $user_problem (@user_problems) {
		my $params = $args{merged} ? _mergeUserProblem($user_problem) : _getUserProblem($user_problem);
		push(@user_problems_to_return, $params);
	}
	return @user_problems_to_return;
}

=head1 getUserProblem

Get a single user problems (or merged user problems).

=head3 input

A hash of input values.

=over

=item * C<info>, a hashref containing:

=over

=item - either a C<course name> or C<course_id>.
=item - either a C<username> or C<user_id>
=item - either a C<set_nam> or C<set_id>
=item - either a C<problem_number> or C<problem_id>

For example, C<{ course_name => 'Precalculus', username=> 'homer', set_id => 3, problem_number => 1}>

=item * C<merged>, a boolean on whether to return a merged user or course user

=item * C<as_result_set>, a boolean.  If true this an object of type
C<DBIx::Class::ResultSet::UserProblem>
if false, a hashrefs of a User Problem or merged User Problem with a Problem.

=back

=head3 output

A hashref of a user problem or merged user problem
or a C<DBIx::Class::ResultSet::UserProblem>

=cut

sub getUserProblem ($self, %args) {
	my $problem  = $self->rs("Problem")->getSetProblem(info => $args{info}, as_result_set => 1);
	my $user_set = $self->rs("UserSet")->getUserSet(info => $args{info}, as_result_set => 1);

	my $user_problem = $self->find({
		problem_id  => $problem->problem_id,
		user_set_id => $user_set->user_set_id,
	});

	# if the problem doesn't exist throw a exception unless skip_throw (used)
	# for checking in addUserProblem

	DB::Exception::UserProblemNotFound->throw(message => "The user problem for the course "
			. $user_set->problem_sets->courses->course_name
			. ", problem set "
			. $user_set->problem_sets->set_name
			. " for user "
			. $user_set->course_users->users->username
			. " and problem number "
			. $problem->problem_number
			. " is not found")
		unless $user_problem || $args{skip_throw};

	return $user_problem if $args{as_result_set};

	return $args{merged} ? _mergeUserProblem($user_problem) : _getUserProblem($user_problem);
}

=head1 addUserProblem

Add a user problem.

=head3 input

A hash of input values.

=over

=item * C<info>, a hashref containing:

=over

=item - either a C<course name> or C<course_id>.
=item - either a C<username> or C<user_id>
=item - either a C<set_nam> or C<set_id>
=item - either a C<problem_number> or C<problem_id>

For example, C<{ course_name => 'Precalculus', username=> 'homer', set_id => 3, problem_number => 1}>

=item *C<params>, a hashref of the valid parameters.  See C<DB::Schema::Result::UserProblem>
for details.

=item * C<merged>, a boolean on whether to return a merged user or course user

=item * C<as_result_set>, a boolean.  If true this an object of type
C<DB::Schema::ResultSet::UserProblem>
if false, a hashrefs of a User Problem or merged User Problem with a Problem.

=back

=head3 output

A hashref of a user problem or merged user problem
or a C<DBIx::Class::ResultSet::UserProblem>

=cut

sub addUserProblem ($self, %args) {
	my $user_problem = $self->getUserProblem(
		info          => $args{info},
		skip_throw    => 1,
		as_result_set => 1
	);

	DB::Exception::UserProblemExists->throw(message => "The user "
			. $user_problem->user_sets->course_users->users->username
			. " already has problem number "
			. $user_problem->problems->problem_number
			. " in set with name "
			. $user_problem->user_sets->problem_sets->set_name)
		if $user_problem;

	my $problem  = $self->rs("Problem")->getSetProblem(info => $args{info}, as_result_set => 1);
	my $user_set = $self->rs("UserSet")->getUserSet(info => $args{info}, as_result_set => 1);

	my $params = clone($args{params} // {});
	$params->{user_problem_params} = {} unless defined $params->{user_problem_params};
	$self->checkParams($params) if defined($args{params});

	$params->{seed}   = int(10000 * rand()) unless defined $params->{seed};
	$params->{status} = 0                   unless defined $params->{status};

	my $problem_to_return = $problem->add_to_user_problems({
		problem_id  => $problem->problem_id,
		user_set_id => $user_set->user_set_id,
		%$params
	});

	return $problem_to_return if $args{as_result_set};
	return $args{merged} ? _mergeUserProblem($problem_to_return) : _getUserProblem($problem_to_return);
}

=head1 updateUserProblem

update a user problem.

=head3 input

A hash of input values.

=over

=item * C<info>, a hashref containing:

=over

=item - either a C<course name> or C<course_id>.
=item - either a C<username> or C<user_id>
=item - either a C<set_nam> or C<set_id>
=item - either a C<problem_number> or C<problem_id>

For example, C<{ course_name => 'Precalculus', username=> 'homer', set_id => 3, problem_number => 1}>

=item *C<params>, a hashref of the valid parameters to be updated.  See C<DB::Schema::Result::UserProblem>
for details.

=item * C<merged>, a boolean on whether to return a merged user or course user

=item * C<as_result_set>, a boolean.  If true this an object of type
C<DB::Schema::ResultSet::UserProblem>
if false, a hashrefs of a User Problem or merged User Problem with a Problem.

=back

=head3 output

A hashref of a user problem or merged user problem
or a C<DBIx::Class::ResultSet::UserProblem>

=cut

sub updateUserProblem ($self, %args) {
	my $user_problem = $self->getUserProblem(
		info          => $args{info},
		skip_throw    => 1,
		as_result_set => 1
	);

	DB::Exception::UserProblemNotFound->throw(message => "The user "
			. getUserInfo($args{info})->{username} // getUserInfo($args{info})->{user_id}
			. " already has problem number "
			. getProblemInfo($args{info})->{problem_number}
			// ("(problem_id): " . getProblemInfo($args{info})->{problem_id})
			. " in set with name"
			. getSetInfo($args{info})->{set_name} // ("(set_id): " . getSetInfo($args{info})->{set_id}))
		unless $user_problem;

	my $params = clone($args{params} // {});
	$self->checkParams($params) if defined($args{params});

	my $problem_to_return = $user_problem->update($params);

	return $problem_to_return if $args{as_result_set};
	return $args{merged} ? _mergeUserProblem($problem_to_return) : _getUserProblem($problem_to_return);
}

=head1 deleteUserProblem

Delete a user problem.

=head3 input

A hash of input values.

=over

=item * C<info>, a hashref containing:

=over

=item - either a C<course name> or C<course_id>.
=item - either a C<username> or C<user_id>
=item - either a C<set_nam> or C<set_id>
=item - either a C<problem_number> or C<problem_id>

For example, C<{ course_name => 'Precalculus', username=> 'homer', set_id => 3, problem_number => 1}>

=item * C<merged>, a boolean on whether to return a merged user or course user

=item * C<as_result_set>, a boolean.  If true this an object of type
C<DB::Schema::ResultSet::UserProblem>
if false, a hashrefs of a User Problem or merged User Problem with a Problem.

=back

=head3 output

A hashref of a user problem or merged user problem
or a C<DBIx::Class::ResultSet::UserProblem>

=cut

sub deleteUserProblem ($self, %args) {
	my $user_problem = $self->getUserProblem(
		info          => $args{info},
		skip_throw    => 1,
		as_result_set => 1
	);

	DB::Exception::UserProblemNotFound->throw(message => "The user "
			. getUserInfo($args{info})->{username} // getUserInfo($args{info})->{user_id}
			. " already has problem number "
			. getProblemInfo($args{info})->{problem_number}
			// ("(problem_id): " . getProblemInfo($args{info})->{problem_id})
			. " in set with name"
			. getSetInfo($args{info})->{set_name} // ("(set_id): " . getSetInfo($args{info})->{set_id}))
		unless $user_problem;

	my $user_problem_to_delete = $user_problem->delete;
	return $user_problem_to_delete if $args{as_result_set};
	return $args{merged} ? _mergeUserProblem($user_problem_to_delete) : _getUserProblem($user_problem_to_delete);
}

# The remaining subroutines are private to simpify the above code.

# This is a small subroutine to shorten access to the db.
sub rs ($self, $table) {
	return $self->result_source->schema->resultset($table);
}

sub checkParams ($self, $params) {

	# Check that the seed is valid (non-negative integer).
	if (defined $params->{seed}) {
		DB::Exception::InvalidParameter->throw(message => "The problem seed must be a non-negative integer.")
			unless $params->{seed} =~ /^\d+$/;
	}

	# Check that other fields/params are correct.
	my $prob_to_check = $self->new($params);
	return $prob_to_check->validParams("user_problem_params");
}

sub _mergeUserProblem ($user_problem) {
	my $user_problem_fields = _getUserProblem($user_problem);
	delete $user_problem_fields->{user_problem_params};
	my $problem_fields = { $user_problem->problems->get_inflated_columns };
	delete $problem_fields->{problem_params};

	# Merge the params (problem_params and user_problem_params).
	my $params = updateAllFields($user_problem->problems->problem_params, $user_problem->user_problem_params);

	# Merge the main fields.
	my $merged_params = updateAllFields($problem_fields, $user_problem_fields);
	$merged_params->{problem_params} = $params;

	return $merged_params;
}

sub _getUserProblem ($user_problem) {
	return {
		$user_problem->get_inflated_columns,
		problem_number => $user_problem->problems->problem_number,
		username       => $user_problem->user_sets->course_users->users->username,
		set_name       => $user_problem->problems->problem_set->set_name,
		course_name    => $user_problem->problems->problem_set->courses->course_name
	};
}

1;
