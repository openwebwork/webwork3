
=pod
 
=head1 DESCRIPTION
 
This is the functionality of a UserSet in WeBWorK.  This package is based on 
<code>DBIx::Class::ResultSet</code>.  The basics are a CRUD for user sets.  
 
=cut

package DB::Schema::ResultSet::UserSet;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

use Data::Dump qw/dd/;

use DB::Utils qw/getCourseInfo getUserInfo getSetInfo updateAllFields/;
use DB::WithDates;
use DB::WithParams;

=pod
=head2 getUserSets

get all UserSet for a given course and user

=cut

sub getUserSets {
	my ( $self, $user_course_info, $as_result_set ) = @_;

	my $user = $self->result_source->schema->resultset("User")->getUser( $user_course_info, 1 );

	my @user_sets   = $self->search( { user_id => $user->user_id } );
	my @user_setids = map { { set_id => $_->set_id }; } @user_sets;

	my $course = $self->result_source->schema->resultset("Course")->getCourse( getCourseInfo($user_course_info), 1 );
	my @problem_sets = $course->problem_sets->search( \@user_setids );

	my @user_sets_to_return = ();
	for my $i ( 0 .. $#user_sets ) {
		my $all_params = { $problem_sets[$i]->get_columns };
		$all_params->{params} = updateAllFields( $problem_sets[$i]->get_inflated_column("params"),
			$user_sets[$i]->get_inflated_column("params") );
		$all_params->{dates} = updateAllFields( $problem_sets[$i]->get_inflated_column("dates"),
			$user_sets[$i]->get_inflated_column("dates") );
		$all_params->{set_type}    = $problem_sets[$i]->set_type;
		$all_params->{login}       = $user->login;
		$all_params->{course_name} = $course->course_name;
		push( @user_sets_to_return, $all_params );

	}
	return @user_sets_to_return;
}

=pod
=head2 getUserSet

get a single UserSet for a given course, user, and ProblemSet

=cut

sub getUserSet {
	my ( $self, $user_set_info, $as_result_set ) = @_;
	my $problem_set_info = { %{ getCourseInfo($user_set_info) }, %{ getSetInfo($user_set_info) } };
	my $user_course_info = { %{ getCourseInfo($user_set_info) }, %{ getUserInfo($user_set_info) } };

	my $problem_set_rs = $self->result_source->schema->resultset("ProblemSet");
	my $user_rs        = $self->result_source->schema->resultset("User");
	my $problem_set    = $problem_set_rs->getProblemSet( $problem_set_info, 1 );
	my $user           = $user_rs->getUser( $user_course_info, 1 );

	my $user_set = $self->find(
		{   'problem_sets.course_id' => $problem_set->course_id,
			'problem_sets.set_id'    => $problem_set->set_id,
			user_id                  => $user->user_id,
		},
		{ prefetch => [qw/problem_sets/] }
	);

	# override the user set params
	my $params = updateAllFields( $problem_set->params, $user_set->params );
	my $dates  = updateAllFields( $problem_set->dates,  $user_set->dates );

	return $user_set if $as_result_set;
	return {
		$problem_set->get_inflated_columns,
		set_type => $problem_set->set_type,
		$user_set->get_columns,
		login  => $user->login,
		dates  => $dates,
		params => $params
	};
}

=pod
=head2 addUserSet

add a single UserSet for a given course, user, and ProblemSet

=cut

sub addUserSet {
	my ( $self, $user_set_info, $as_result_set ) = @_;
	my $problem_set_info = { %{ getCourseInfo($user_set_info) }, %{ getSetInfo($user_set_info) } };
	my $user_course_info = { %{ getCourseInfo($user_set_info) }, %{ getUserInfo($user_set_info) } };

}

=pod
=head2 updateUserSet

update a single UserSet for a given course, user, and ProblemSet

=cut

sub updateUserSet {
	my ( $self, $user_set_info, $user_set_params, $as_result_set ) = @_;

	my $merged_set  = $self->getUserSet($user_set_info);
	my $problem_set = $self->result_source->schema->resultset("ProblemSet")
		->getProblemSet( { course_id => $merged_set->{course_id}, set_id => $merged_set->{set_id} } );

	# override the user set params
	my $params = {%$user_set_params};
	$params->{params} = updateAllFields( $merged_set->{params}, $user_set_params->{params} );
	$params->{dates}  = updateAllFields( $merged_set->{dates},  $user_set_params->{dates} );
	$params->{type}   = $merged_set->{type};

	my $user_set_to_update = $self->new($params);
	$user_set_to_update->validParams();
}

1;
