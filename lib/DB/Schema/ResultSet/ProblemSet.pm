package DB::Schema::ResultSet::ProblemSet;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

use Carp;
use Clone qw/clone/;
use Data::Dumper;

use DB::Utils qw/getCourseInfo getUserInfo getSetInfo updateAllFields/;

our $SET_TYPES = {
	"HW"     => 1,
	"QUIZ"   => 2,
	"JITAR"  => 3,
	"REVIEW" => 4,
};

use DB::Exception;

=head1 DESCRIPTION

This is the functionality of a ProblemSet in WeBWorK.  This package is based on
C<DBIx::Class::ResultSet>.  The basics are a CRUD for ProblemSets;

=head2 getProblemSets

This gets a list of all ProblemSet (and set-like objects) stored in the database in the C<courses> table.

=head3 input

none

=head3 output

An array of courses as a C<DBIx::Class::ResultSet::ProblemSet> object.

=cut

sub getAllProblemSets {
	my $self           = shift;
	my $problem_set_rs = $self->search(undef, { prefetch => 'courses' });

	my @all_sets = ();
	while (my $set = $problem_set_rs->next) {
		my $expanded_set =
			{ $set->get_inflated_columns, $set->courses->get_inflated_columns, set_type => $set->set_type };
		delete $expanded_set->{type};
		push(@all_sets, $expanded_set);
	}

	return @all_sets;
}

####
#
#  The following is CRUD for problem sets in a given course
#
####

=head2 getProblemSets

Get all problem sets for a given course

=cut

sub getProblemSets {
	my ($self, $course_info, $set_params, $as_result_set) = @_;
	# my $search_params = $self->getCourseInfo($course_info);    ## return a hash of course info
	my $course_rs = $self->result_source->schema->resultset("Course");
	my $course    = $course_rs->getCourse($course_info, 1);

	my $problem_sets = $self->search({ 'me.course_id' => $course->course_id }, { prefetch => ["courses"] });
	my $sets         = _formatSets($problem_sets);
	return $as_result_set ? $problem_sets : @$sets;
}

sub getHWSets {
	my ($self, $course_info, $as_result_set) = @_;
	my $search_params = getCourseInfo($course_info);    # pull out the course_info that is passed
	$search_params->{'me.type'} = 1;                    # set the type to search for.

	my $problem_sets = $self->search($search_params, { prefetch => ["courses"] });
	my $sets         = _formatSets($problem_sets);
	return $as_result_set ? $problem_sets : @$sets;
}

=head2 getQuizzes

Get all quizzes for a given course

=cut

sub getQuizzes {
	my ($self, $course_info, $as_result_set) = @_;
	my $search_params = getCourseInfo($course_info);    # pull out the course_info that is passed
	$search_params->{'me.type'} = 2;                    # set the type to search for.

	my $problem_sets = $self->search($search_params, { prefetch => ["courses"] });
	my $sets         = _formatSets($problem_sets);
	return $as_result_set ? $problem_sets : @$sets;
}

=head2 getReviewSets

Get all review sets for a given course

=cut

sub getReviewSets {
	my ($self, $course_info, $as_result_set) = @_;
	my $search_params = getCourseInfo($course_info);    # pull out the course_info that is passed
	$search_params->{'me.type'} = 3;                    # set the type to search for.

	my $problem_sets = $self->search($search_params, { prefetch => ["courses"] });
	my $sets         = _formatSets($problem_sets);
	return $as_result_set ? $problem_sets : @$sets;
}

=head2 getProblemSet

Get one HW set for a given course

=cut

sub getProblemSet {
	my ($self, $course_set_info, $as_result_set) = @_;
	my $course_info = getCourseInfo($course_set_info);
	my $course_rs   = $self->result_source->schema->resultset("Course");
	my $course      = $course_rs->getCourse($course_info, 1);

	my $problem_set = $course->problem_sets->find(getSetInfo($course_set_info));
	DB::Exception::SetNotInCourse->throw(
		set_name    => getSetInfo($course_set_info),
		course_name => $course->course_name
	) unless defined($problem_set);

	return $problem_set if $as_result_set;
	my $set = { $problem_set->get_inflated_columns, set_type => $problem_set->set_type };
	delete $set->{type};
	return $set;

}

=head2 addProblemSet

Get one HW set for a given course

=cut

sub addProblemSet {
	my ($self, $course_info, $params, $as_result_set) = @_;
	my $course = $self->result_source->schema->resultset("Course")->getCourse(getCourseInfo($course_info), 1);

	my $set_params = clone($params);
	$set_params->{type} = $SET_TYPES->{ $set_params->{set_type} || 'HW' };
	delete $set_params->{set_type};

	DB::Exception::ParametersNeeded->throw(message => "You must defined the field set_name in the 2nd argument")
		unless defined($set_params->{set_name});

	## check if the set exists.
	my $search_params = { course_id => $course->course_id, set_name => $set_params->{set_name} };

	my $problem_set = $self->find($search_params, prefetch => 'courses');
	DB::Exception::SetAlreadyExists->throws(set_name => $set_params->{set_name}, course_name => $course->course_name)
		if defined($problem_set);
	my $set_obj = $self->new($set_params);

	$set_obj->validDates(undef, 'set_dates');
	$set_obj->validParams(undef, 'set_params');

	my $new_set = $course->add_to_problem_sets($set_params, 1);

	return $new_set if $as_result_set;
	my $set = { $new_set->get_inflated_columns, set_type => $new_set->set_type };
	delete $set->{type};
	return $set;
}

=head2 updateProblemSet

Update a problem set (HW, Quiz, etc.) for a given course

=cut

sub updateProblemSet {
	my ($self, $course_set_info, $updated_params, $as_result_set) = @_;

	my $problem_set = $self->getProblemSet($course_set_info, 1);
	my $set_params  = { $problem_set->get_inflated_columns };

	my $params = clone($updated_params);
	if (defined $params->{set_type}) {
		$params->{type} = $SET_TYPES->{ $params->{set_type} };
		delete $params->{set_type};
	}

	my $params2 = updateAllFields($set_params, $params);
	my $set_obj = $self->new($params2);

	## check the parameters are valid.
	$set_obj->validDates(undef, 'set_dates');
	$set_obj->validParams(undef, 'set_params');
	my $updated_set = $problem_set->update({ $set_obj->get_inflated_columns });
	return $updated_set if $as_result_set;
	my $set = { $updated_set->get_inflated_columns, set_type => $updated_set->set_type };
	delete $set->{type};
	return $set;
}

=head2 deleteProblemSet

Delete a problem set (HW, Quiz, etc.) for a given course

=cut

sub deleteProblemSet {
	my ($self, $course_set_info, $as_result_set) = @_;

	my $set_to_delete = $self->getProblemSet($course_set_info, 1);
	$set_to_delete->delete;

	return $set_to_delete if $as_result_set;
	my $set = { $set_to_delete->get_inflated_columns, set_type => $set_to_delete->set_type };
	delete $set->{type};
	return $set;
}

###
#
# Versions of problem sets
#
##

=head2 newSetVersion

Creates a new version of a problem set for a given course for either any entire course or a specific user

=head3 inputs

=over

=item * A hashref with

=over

=item - course_id or course_name

=item - set_id or set_name

=item - username or user_id (optional)

=back

=back

=head4 output

=cut

sub newSetVersion {
	my ($self, $info) = @_;
	my $course_set_info = { %{ getCourseInfo($info) }, %{ getSetInfo($info) } };
	my $problem_set     = $self->getProblemSet($course_set_info);

	# if $info also contains user info
	my @fields = keys %$info;
	if (scalar(@fields) == 3) {
		my $user_info = getUserInfo($info);

	} else {
		my $user_set_rs = $self->result_source->schema->resultset("UserSet");

		# @user_sets = $user_set_rs->get
	}
	return $problem_set;
}

## the following are private methods used in this module

# return the Course resultset

sub _course_rs {
	return shift->result_source->schema->resultset("Course");
}

# return the Problem resultset

sub _problem_rs {
	return shift->result_source->schema->resultset("Problem");
}

sub _formatSets {
	my $problem_sets = shift;
	my @sets         = ();
	while (my $set = $problem_sets->next) {
		my $expanded_set = { $set->get_inflated_columns, set_type => $set->set_type };
		delete $expanded_set->{type};
		push(@sets, $expanded_set);
	}
	return \@sets;
}

1;
