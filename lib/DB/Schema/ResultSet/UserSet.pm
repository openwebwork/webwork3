
=pod

=head1 DESCRIPTION

This is the functionality of a UserSet in WeBWorK.  This package is based on
<code>DBIx::Class::ResultSet</code>.  The basics are a CRUD for user sets.

=cut

package DB::Schema::ResultSet::UserSet;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

use Try::Tiny;
use Data::Dump qw/dd/;

use DB::Utils qw/getCourseInfo getUserInfo getSetInfo updateAllFields/;
use DB::WithDates;
use DB::WithParams;

=pod
=head2 getUserSets

get all UserSet for a given course and either a given user or given set

=head3 input
=item *
A hashref containing
=item -
Either a course_name or course_id
=item -
information on either a set (set_name or set_id) or a user (user_id or login)

=cut

sub getUserSets {
	my ( $self, $info, $as_result_set ) = @_;
	my $course = $self->result_source->schema->resultset("Course")->getCourse( getCourseInfo($info), 1 );

	my ( $user_info, $set_info );

	# determine if this is a set of user set based on a set or a user
	try {    # one of these will throw an error
		$user_info = getUserInfo($info);
	}
	finally { };
	try {
		$set_info = getSetInfo($info);
	}
	finally { };

	if ( scalar( keys %$user_info ) == 1 ) {    # all user sets for a given user
		my $user = $self->result_source->schema->resultset("User")
			->getUser( { course_id => $course->course_id, %$user_info }, 1 );

		my @user_sets   = $self->search( { user_id => $user->user_id } );
		my @user_setids = map { { set_id => $_->set_id }; } @user_sets;

		my @problem_sets = $course->problem_sets->search( \@user_setids );

		my @user_sets_to_return = ();
		for my $i ( 0 .. $#user_sets ) {
			my $all_params = {
				$problem_sets[$i]->get_columns,
				params => updateAllFields(
					$problem_sets[$i]->get_inflated_column("params"),
					$user_sets[$i]->get_inflated_column("params")
				),
				dates => updateAllFields(
					$problem_sets[$i]->get_inflated_column("dates"),
					$user_sets[$i]->get_inflated_column("dates")
				),
				set_type    => $problem_sets[$i]->set_type,
				login       => $user->login,
				course_name => $course->course_name,
				set_version => $user_sets[$i]->set_version
			};
			push( @user_sets_to_return, $all_params );

		}
		return @user_sets_to_return;
	}
	elsif ( scalar( keys %$set_info ) == 1 ) {    # all user sets for a given set
		my $problem_set = $self->result_source->schema->resultset("ProblemSet")
			->getProblemSet( { course_id => $course->course_id, %$set_info }, 1 );

		my @user_sets           = $self->search( { set_id => 1 }, { prefetch => { course_users => 'users' } } );
		my @user_sets_to_return = ();
		for my $i ( 0 .. $#user_sets ) {
			my $all_params = {
				$problem_set->get_columns,
				params => updateAllFields(
					$problem_set->get_inflated_column("params"),
					$user_sets[$i]->get_inflated_column("params")
				),
				dates => updateAllFields(
					$problem_set->get_inflated_column("dates"),
					$user_sets[$i]->get_inflated_column("dates")
				),
				set_type    => $problem_set->set_type,
				login       => $user_sets[$i]->course_users->users->login,
				course_name => $course->course_name,
				set_version => $user_sets[$i]->set_version
			};
			push( @user_sets_to_return, $all_params );
		}
		return @user_sets_to_return;
	}
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
		dates  => $dates,
		params => $params,
		login  => $user->login
	};
}

=pod
=head2 addUserSet

add a single UserSet for a given course, user, and ProblemSet

=cut

# sub addUserSet {
# 	my ( $self, $user_set_info, $user_set_params, $as_result_set ) = @_;
# 	my $problem_set_info = { %{ getCourseInfo($user_set_info) }, %{ getSetInfo($user_set_info) } };
# 	my $user_course_info = { %{ getCourseInfo($user_set_info) }, %{ getUserInfo($user_set_info) } };

# }

=pod
=head2 updateUserSet

update a single UserSet for a given course, user, and ProblemSet

=cut

sub updateUserSet {
	my ( $self, $set_info, $user_set_params, $as_result_set ) = @_;

	my $user_set   = $self->getUserSet( $set_info, 1 );
	my $merged_set = $self->getUserSet($set_info);

	my @keys = grep { $_ ne "params" && $_ ne "dates" } keys %$user_set_params;

	for my $key (@keys) {
		$merged_set->{$key} = $user_set_params->{$key};
	}
	for my $key ( keys %{ $user_set_params->{params} } ) {
		$merged_set->{params}->{$key} = $user_set_params->{params}->{$key};
	}
	for my $key ( keys %{ $user_set_params->{dates} } ) {
		$merged_set->{dates}->{$key} = $user_set_params->{dates}->{$key};
	}

	# convert the set_type (a string) to type ( a number)
	$merged_set->{type} = $DB::Schema::ResultSet::ProblemSet::SET_TYPES->{ $merged_set->{set_type} };

	# delete fields that are not in the database,  TODO: automate this.
	for my $key (qw/set_type set_name course_id login/) {
		delete $merged_set->{$key};
	}

	my $problem_set = $user_set->update($merged_set);

	# check for valid params
	$problem_set->validParams();
	$problem_set->validDates();

	return $problem_set if $as_result_set;
	return { $problem_set->get_inflated_columns };
}

1;
