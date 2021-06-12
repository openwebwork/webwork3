package DB::Schema::ResultSet::ProblemSet;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

use Carp;
use Data::Dump qw/dd dump/;

use DB::Utils qw/getCourseInfo getUserInfo getSetInfo updateAllFields/;

use Exception::Class (
		'SetNotInCourseException' => {fields => ['set_name','course_name']},
		'ParametersException'
	);

our $SET_TYPES = {
		"HW" => 1,
		"QUIZ" => 2,
		"JITAR" => 3,
		"REVIEW" => 4,
	};

=pod
 
=head1 DESCRIPTION
 
This is the functionality of a ProblemSet in WeBWorK.  This package is based on 
<code>DBIx::Class::ResultSet</code>.  The basics are a CRUD for ProblemSets;  
 
=cut

=pod
=head2 getProblemSets

This gets a list of all ProblemSet (and set-like objects) stored in the database in the <code>courses</codes> table. 

=head3 input 

none

=head3 output 

An array of courses as a <code>DBIx::Class::ResultSet::ProblemSet</code> object.  

=cut

sub getAllProblemSets {
	my $self = shift;
	my @all_sets = $self->search(undef,{ prefetch => 'courses' }); 
	return map { {$_->get_inflated_columns,$_->courses->get_columns};} @all_sets;
} 

####
#
#  The following is CRUD for problem sets in a given course
#
####

=pod
=head2 getProblemSets

Get all problem sets for a given course


=cut

sub getProblemSets {
	my ($self,$course_info,$set_params,$as_result_set) = @_;
	my $search_params = getCourseInfo($course_info); ## return a hash of course info
	
	my @sets = $self->search($search_params,{ prefetch => ["courses"] });
	return map { {$_->get_inflated_columns}; } @sets; 
}

=pod
=head2 getHWSets

Get all hw sets for a given course


=cut

sub getHWSets {
	my ($self,$course_info,$as_result_set) = @_;
	my $search_params = getCourseInfo($course_info);  # pull out the course_info that is passed
	$search_params->{'me.type'} = 1;  # set the type to search for. 
	
	my @sets = $self->search($search_params,{ prefetch => ["courses"] });
	return \@sets if $as_result_set; 
	return map { {$_->get_inflated_columns}; } @sets; 
}


=pod
=head2 getQuizzes

Get all quizzes for a given course


=cut

sub getQuizzes {
	my ($self,$course_info,$as_result_set) = @_;
	my $search_params = getCourseInfo($course_info);  # pull out the course_info that is passed
	$search_params->{'me.type'} = 2;  # set the type to search for. 
	
	my @sets = $self->search($search_params,{ prefetch => ["courses"] });
	return \@sets if $as_result_set; 
	return map { {$_->get_inflated_columns}; } @sets; 
}

=pod
=head2 getProblemSet

Get one HW set for a given course


=cut

sub getProblemSet {
	my ($self,$course_set_info,$as_result_set) = @_;
	my $course_info = getCourseInfo($course_set_info); 
	my $course_rs = $self->result_source->schema->resultset("Course");
	my $course = $course_rs->getCourse($course_info,1);

	my $search_params = {course_id=>$course->course_id,%{getSetInfo($course_set_info)}}; 
	
	my $set = $self->find($search_params,prefetch => 'courses');
	SetNotInCourseException->throw(set_name=>getSetInfo($course_set_info),course_name=>$course->course_name)
		unless defined($set); 

	return $set if $as_result_set; 
	return {$set->get_inflated_columns}; 

}

=pod
=head2 addProblemSet

Get one HW set for a given course


=cut

sub addProblemSet {
	my ($self,$course_info,$set_params,$as_result_set) = @_;
	my $course_rs = $self->result_source->schema->resultset("Course");
	my $course = $course_rs->getCourse(getCourseInfo($course_info),1);

	
	ParametersException->throw(error => "You must defined the field set_name in the 2nd argument") 
		unless defined($set_params->{set_name}); 

	## check if the set exists. 
	my $search_params = {course_id=>$course->course_id,set_name => $set_params->{set_name}}; 

	my $set = $self->find($search_params,prefetch => 'courses');
	croak "The Problem set with name " . $set_params->{set_name} . " already exists." if defined($set);

	$set_params->{type} = $SET_TYPES->{$set_params->{set_type}};
	delete $set_params->{set_type};


	my $set_obj = $self->new($set_params);
	## check the parameters are valid. 
	# $set_obj->setParamsAndDates;
	$set_obj->validDates(); 
	$set_obj->validParams();
	
	my $new_set = $course->add_to_problem_sets($set_params,1);

	return $new_set if $as_result_set;
	return {$new_set->get_inflated_columns};
}

=pod
=head2 updateProblemSet

Update a problem set (HW, Quiz, etc.) for a given course


=cut

sub updateProblemSet {
	my ($self,$course_set_info,$updated_params,$as_result_set) = @_;

	my $set = $self->getProblemSet($course_set_info,1);
	my $set_params = {$set->get_inflated_columns};

	my $params = updateAllFields($set_params,$updated_params);
	my $set_obj = $self->new($params);

	## check the parameters are valid. 
	$set_obj->validDates(); 
	$set_obj->validParams();
	my $updated_set = $set->update({$set_obj->get_inflated_columns});
	return $updated_set if $as_result_set;
	return {$updated_set->get_inflated_columns};
}


=pod
=head2 deleteProblemSet

Delete a problem set (HW, Quiz, etc.) for a given course


=cut

sub deleteProblemSet {
	my ($self,$course_set_info,$as_result_set) = @_;

	my $set_to_delete = $self->getProblemSet($course_set_info,1);
	$set_to_delete->delete; 

	return $set_to_delete if $as_result_set;
	return {$set_to_delete->get_inflated_columns};
}


1;