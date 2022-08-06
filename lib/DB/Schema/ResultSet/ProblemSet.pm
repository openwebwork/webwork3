package DB::Schema::ResultSet::ProblemSet;

use strict;
use warnings;
use feature 'signatures';
no warnings qw/experimental::signatures/;

use base 'DBIx::Class::ResultSet';

use Clone qw/clone/;

use DB::Utils qw/getCourseInfo getUserInfo getSetInfo updateAllFields/;

our $SET_TYPES = {
	'HW'     => 1,
	'QUIZ'   => 2,
	'JITAR'  => 3,
	'REVIEW' => 4,
};

our $SUBCLASS_NAMES = {
	1 => 'HWSet',
	2 => 'Quiz',
	3 => 'JITAR',
	4 => 'ReviewSet'
};

use DB::Exception;

=head1 DESCRIPTION

This is the functionality of a ProblemSet in WeBWorK.  This package is based on
C<DBIx::Class::ResultSet>.  The basics are a CRUD for ProblemSets.

Note: a ProblemSet is an abstract class for HWSet, Quiz, ReviewSet, which differ
in parameter and dates types.

=head2 getProblemSets

This gets a list of all ProblemSet (and set-like objects) stored in the database
in the C<problem_set> table.

=head3 input

=over
=item - C<as_result_set>, a boolean.  If true this result an array of C<DBIx::Class::ResultSet::ProblemSet>
if false, an array of hashrefs of ProblemSet.

=back

=head3 output

An array of courses as a C<DBIx::Class::ResultSet::ProblemSet> object.

=cut

sub getAllProblemSets ($self, %args) {
	my @problem_sets = $self->search();

	return @problem_sets if $args{as_result_set};

	my @all_sets = ();
	for my $set (@problem_sets) {
		my $expanded_set =
			{ $set->get_inflated_columns, $set->courses->get_inflated_columns, set_type => $set->set_type };
		delete $expanded_set->{type};
		push(@all_sets, $expanded_set);
	}

	return @all_sets;
}

# The following is CRUD for problem sets in a given course

=head2 getProblemSets

Get all problem sets for a given course

=head3 input

A hash of input values.

=over

=item * C<info>, either a course name or course_id.

For example, C<{ course_name => 'Precalculus'}> or C<{course_id => 3}>

=item * C<as_result_set>, a boolean.  If true this result an array of
C<DBIx::Class::ResultSet::ProblemSet>
if false, an array of hashrefs of ProblemSet.


=back

=head3 output

An array of Users (as hashrefs) or an array of C<DBIx::Class::ResultSet::ProblemSet>

=cut

sub getProblemSets ($self, %args) {
	my $course = $self->rs('Course')->getCourse(info => $args{info}, as_result_set => 1);

	my @problem_sets = $self->search({ 'course_id' => $course->course_id });

	return @problem_sets if $args{as_result_set};

	my $sets = _formatSets(\@problem_sets);
	return @$sets;
}

=head2 getHWSets

Get all homework sets (C<ProblemSet> of type C<HWSet>) for a given course

=head3 input

A hash of input values.

=over

=item * C<info>, either a course name or course_id.

For example, C<{ course_name => 'Precalculus'}> or C<{course_id => 3}>

=item * C<as_result_set>, a boolean.  If true this result an array of
C<DBIx::Class::ResultSet::HWSet>
if false, an array of hashrefs of ProblemSet.


=back

=head3 output

An array of homework sets (as hashrefs) or an arrayref of C<DBIx::Class::ResultSet::HWSet>

=cut

sub getHWSets ($self, %args) {
	my $p             = getCourseInfo($args{info});    # pull out the course_info that is passed
	my $search_params = {};
	for my $key (keys %$p) {
		$search_params->{"courses.$key"} = $p->{$key};
	}
	$search_params->{'type'} = 1;

	my @problem_sets = $self->search($search_params, { join => 'courses' });
	my $sets         = _formatSets(\@problem_sets);
	return $args{as_result_set} ? @problem_sets : @$sets;
}

=head2 getQuizzes

Get all quizzes (C<ProblemSet> of type C<Quiz>) for a given course

=head3 input

A hash of input values.

=over

=item * C<info>, either a course name or course_id.

For example, C<{ course_name => 'Precalculus'}> or C<{course_id => 3}>

=item * C<as_result_set>, a boolean.  If true this result an array of
C<DBIx::Class::ResultSet::HWSet>
if false, an array of hashrefs of Quiz.


=back

=head3 output

An array of quizzes (as hashrefs) or an arrayref of C<DBIx::Class::ResultSet::Quiz>

=cut

sub getQuizzes ($self, %args) {
	my $p             = getCourseInfo($args{info});    # pull out the course_info that is passed
	my $search_params = {};
	for my $key (keys %$p) {
		$search_params->{"courses.$key"} = $p->{$key};
	}
	$search_params->{'type'} = 2;

	my @problem_sets = $self->search($search_params, { join => 'courses' });
	my $sets         = _formatSets(\@problem_sets);
	return $args{as_result_set} ? @problem_sets : @$sets;
}

=head2 getReviewSets

Get all quizzes (C<ProblemSet> of type C<ReviewSet>) for a given course

=head3 input

A hash of input values.

=over

=item * C<info>, either a course name or course_id.

For example, C<{ course_name => 'Precalculus'}> or C<{course_id => 3}>

=item * C<as_result_set>, a boolean.  If true this result an array of
C<DBIx::Class::ResultSet::ReviewSet>
if false, an array of hashrefs of HWSet.


=back

=head3 output

An array of review sets (as hashrefs) or an arrayref of C<DBIx::Class::ResultSet::ReviewSet>

=cut

sub getReviewSets ($self, %args) {
	my $p             = getCourseInfo($args{info});    # pull out the course_info that is passed
	my $search_params = {};
	for my $key (keys %$p) {
		$search_params->{"courses.$key"} = $p->{$key};
	}
	$search_params->{'type'} = 3;

	my @problem_sets = $self->search($search_params, { join => 'courses' });
	my $sets         = _formatSets(\@problem_sets);
	return $args{as_result_set} ? @problem_sets : @$sets;
}

=head2 getProblemSet

Get a single ProblemSet for a given course

=head3 input

A hash of input values.

=over

=item * C<info>, a hash including

=over
=item * either a course name or course_id.
=item * either a set name or set_id

=back

For example, C<{ course_name => 'Precalculus', set_id => 3}> or
C<{course_id => 3, set_name ='HW #1'}>

=item * C<as_result_set>, a boolean.  If true this an object of type
C<DBIx::Class::ResultSet::ProblemSet>
if false, a hashrefs of ProblemSet.


=back

=head3 output

An hashref of a problem set or an object of type C<DBIx::Class::ResultSet::ProblemSet>

=cut

sub getProblemSet ($self, %args) {
	my $course_info = getCourseInfo($args{info});
	my $set_info    = getSetInfo($args{info});
	my $course      = $self->rs('Course')->getCourse(info => $course_info, as_result_set => 1);

	my $problem_set = $course->problem_sets->find($set_info);

	DB::Exception::SetNotInCourse->throw(
		set_name    => $set_info,
		course_name => $course->course_name
	) unless defined($problem_set) || $args{skip_throw};

	return $problem_set if $args{as_result_set};
	my $set = { $problem_set->get_inflated_columns, set_type => $problem_set->set_type };
	delete $set->{type};
	return $set;
}

=head2 addProblemSet

Add one HW set for a given course

=head3 input

A hash of input values.

=over

=item * C<info>, a hash including

=over
=item - either a course name or course_id.
=item - either a set name or set_id

=back

For example, C<{ course_name => 'Precalculus', set_id => 3}> or
C<{course_id => 3, set_name ='HW #1'}>

=item *C<params>, a hash including all parameters for the set.

=over
=item - C<set_name>: name of the set
=item - C<type>: the type of problem set
=item - C<set_visible>: (boolean) visiblility of the set to a student
=item - C<set_dates>: a hash of dates related to the problem set.  Note: different types have
different date fields.
=item - C<set_params>: a hash of additional parameters of the problem set.  Note: different problem set types
have different params fields.

=back

Note: depending
on the type of problem set, the C<set_params> and C<set_dates> may be different.

=item * C<as_result_set>, a boolean.  If true this an object of type
C<DBIx::Class::ResultSet::ProblemSet>
if false, a hashrefs of ProblemSet.


=back

=head3 output

An hashref of a problem set or an object of type C<DBIx::Class::ResultSet::ProblemSet>

=cut

sub addProblemSet {
	my ($self, %args) = @_;
	my $course = $self->rs('Course')->getCourse(info => getCourseInfo($args{params}), as_result_set => 1);

	my $set_params = clone $args{params};
	$set_params->{type} = $SET_TYPES->{ $set_params->{set_type} || 'HW' };
	# Delete a few fields that may be passed in but are not in the database
	# Note: on client-side set_id=0 means that the set is new, so delete this
	#  and it will be determined.
	for my $key (qw/course_id course_name set_type set_id/) {
		delete $set_params->{$key} if defined $set_params->{$key};
	}

	DB::Exception::ParametersNeeded->throw(message => 'You must defined the field set_name in the params argument')
		unless defined($set_params->{set_name});

	# Check if the set exists.
	my $problem_set = $self->getProblemSet(
		info => {
			course_id => $course->course_id,
			set_name  => $set_params->{set_name}
		},
		as_result_set => 1,
		skip_throw    => 1
	);

	DB::Exception::SetAlreadyExists->throw(message =>
			"The problem set with name $set_params->{set_name} already exists in the course $course->course_name")
		if defined($problem_set);

	# Check that fields/dates/parameters are valid
	my $set_obj = $self->new($set_params);
	$set_obj->validate(field_name => 'set_dates');
	$set_obj->validate(field_name => 'set_params');

	my $new_set = $course->add_to_problem_sets($set_params);

	return $new_set if $args{as_result_set};
	my $set = { $new_set->get_inflated_columns, set_type => $new_set->set_type };
	delete $set->{type};
	return $set;
}

=head2 updateProblemSet

Update a problem set (HW, Quiz, etc.) for a given course

=head3 input

A hash of input values.

=over

=item * C<info>, a hash including

=over
=item - either a course name or course_id.
=item - either a set name or set_id

=back

For example, C<{ course_name => 'Precalculus', set_id => 3}> or
C<{course_id => 3, set_name ='HW #1'}>

=item *C<params>, a hash including all parameters for the set.

=over
=item - C<set_name>: name of the set
=item - C<type>: the type of problem set
=item - C<set_visible>: (boolean) visiblility of the set to a student
=item - C<set_dates>: a hash of dates related to the problem set.  Note: different types have
different date fields.
=item - C<set_params>: a hash of additional parameters of the problem set.  Note: different problem set types
have different params fields.

=back

Note: depending
on the type of problem set, the C<set_params> and C<set_dates> may be different.

=item * C<as_result_set>, a boolean.  If true this an object of type
C<DBIx::Class::ResultSet::ProblemSet>
if false, a hashrefs of ProblemSet.


=back

=head3 output

An hashref of a problem set or an object of type C<DBIx::Class::ResultSet::ProblemSet>

=cut

sub updateProblemSet ($self, %args) {
	my $problem_set = $self->getProblemSet(info => $args{info}, as_result_set => 1);
	my $set_params  = { $problem_set->get_inflated_columns };

	my $params = clone($args{params});
	if (defined $params->{set_type}) {
		$params->{type} = $SET_TYPES->{ $params->{set_type} };
		delete $params->{set_type};
	}

	my $params2;

	# If the problem set type changed, don't update the params, just used the ones passed in.
	if (!defined($params->{type}) || $problem_set->type == $params->{type}) {
		$params2 = updateAllFields($set_params, $params);
	} else {
		# The set type is changing, so assume that the set_dates and set_params are deleted
		# unless passed in.
		$params2 = $params;
		unless (defined $params2->{set_dates}) {
			if ($params2->{type} == 1) {    # HomeworkSet
				$params2->{set_dates} = {
					open            => 0,
					reduced_scoring => 0,
					due             => 0,
					answer          => 0,
				};
			} elsif ($params2->{type} == 2) {    # Quiz
				$params2->{set_dates} = {
					open   => 0,
					due    => 0,
					answer => 0,
				};
			} elsif ($params2->{type} == 3) {    # JITAR
				$params2->{set_dates} = {
					open            => 0,
					reduced_scoring => 0,
					due             => 0,
					answer          => 0,
				};
			} elsif ($params2->{type} == 4) {    # ReviewSet
				$params2->{set_dates} = {
					open   => 0,
					closed => 0
				};
			}
		}
	}
	$params2->{set_params} = {} unless defined($params2->{set_params});
	my $set_obj = $self->new($params2);

	# Check the parameters are valid.
	$set_obj->validate(field_name => 'set_dates')  if $set_obj->set_dates;
	$set_obj->validate(field_name => 'set_params') if $set_obj->set_params;
	my $updated_set = $problem_set->update({ $set_obj->get_inflated_columns });
	return $updated_set if $args{as_result_set};
	my $set = { $updated_set->get_inflated_columns, set_type => $updated_set->set_type };
	delete $set->{type};
	return $set;
}

=head2 deleteProblemSet

Delete a problem set (HW, Quiz, etc.) for a given course

=head3 input

A hash of input values.

=over

=item * C<info>, a hash including

=over
=item - either a course name or course_id.
=item - either a set name or set_id

=back

For example, C<{ course_name => 'Precalculus', set_id => 3}> or
C<{course_id => 3, set_name ='HW #1'}>

=item * C<as_result_set>, a boolean.  If true this an object of type
C<DBIx::Class::ResultSet::ProblemSet>
if false, a hashrefs of ProblemSet.


=back

=head3 output

An hashref of the deleted problem set or an object of type C<DBIx::Class::ResultSet::ProblemSet>

=cut

sub deleteProblemSet ($self, %args) {

	my $set_to_delete = $self->getProblemSet(info => $args{info}, as_result_set => 1);
	$set_to_delete->delete;

	return $set_to_delete if $args{as_result_set};
	my $set = { $set_to_delete->get_inflated_columns, set_type => $set_to_delete->set_type };
	delete $set->{type};
	return $set;
}

# The following are private methods used in this module.

sub _formatSets ($problem_sets) {
	my @sets = ();
	for my $set (@$problem_sets) {
		my $expanded_set = { $set->get_inflated_columns, set_type => $set->set_type };
		delete $expanded_set->{type};
		push(@sets, $expanded_set);
	}
	return \@sets;
}

# just a small subroutine to shorten access to the db.

sub rs ($self, $table) {
	return $self->result_source->schema->resultset($table);
}

1;
