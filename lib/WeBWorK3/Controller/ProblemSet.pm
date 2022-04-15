package WeBWorK3::Controller::ProblemSet;
use warnings;
use strict;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Try::Tiny;
use Mojo::JSON qw/true false/;

sub getAllProblemSets ($self) {
	my @all_problem_sets = $self->schema->resultset("ProblemSet")->getAllProblemSets;
	$self->render(json => \@all_problem_sets);
	return;
}

sub getProblemSets ($self) {
	my @problem_sets =
		$self->schema->resultset("ProblemSet")->getProblemSets(info => { course_id => int($self->param('course_id')) });
	# convert booleans
	for my $set (@problem_sets) {
		$set->{set_visible} = $set->{set_visible} ? true : false;
	}
	$self->render(json => \@problem_sets);
	return;
}

sub getProblemSet ($self) {
	my $problem_set = $self->schema->resultset("ProblemSet")->getProblemSet(
		info => {
			course_id => int($self->param('course_id')),
			set_id    => int($self->param('set_id'))
		}
	);
	$self->render(json => $problem_set);
	return;
}

## update the course given by course_id with given params

sub updateProblemSet ($self) {
	my $problem_set = $self->schema->resultset("ProblemSet")->updateProblemSet(
		info => {
			course_id => int($self->param('course_id')),
			set_id    => int($self->param('set_id'))
		},
		params => $self->req->json
	);

	$self->render(json => $problem_set);
	return;
}

sub addProblemSet ($self) {
	my $problem_set = $self->schema->resultset("ProblemSet")->addProblemSet(
		params => {
			course_id => int($self->param('course_id')),
			%{ $self->req->json }
		}
	);
	$self->render(json => $problem_set);
	return;
}

sub deleteProblemSet ($self) {
	my $problem_set = $self->schema->resultset("ProblemSet")->deleteProblemSet(
		info => {
			course_id => int($self->param('course_id')),
			set_id    => int($self->param('set_id'))
		}
	);
	$self->render(json => $problem_set);
	return;
}

# CRUD for user sets

# Get all user sets for a single course.

sub getAllUserSets ($self) {
	my @user_sets = $self->schema->resultset('UserSet')->getAllUserSetsForCourse(info => {
		course_id => int($self->param('course_id'))
	});
	$self->render(json => \@user_sets);
	return;
}

# Get all user sets in a course for a single user or single set.

sub getUserSets ($self) {
	my @user_sets;
	my $info = { course_id => int($self->param('course_id')) };
	if ($self->param('set_id')) {
		$info->{set_id} = int($self->param('set_id'));
		@user_sets = $self->schema->resultset('UserSet')->getUserSetsForSet(info => $info);
	} elsif ($self->param('user_id')) {
		$info->{user_id} = int($self->param('user_id'));
		@user_sets = $self->schema->resultset('UserSet')->getUserSetsForUser(info => $info);
	}
	# Remove the course_name for each of the user sets.
	for my $user_set (@user_sets) {
		delete $user_set->{course_name};
	}
	$self->render(json => \@user_sets);
	return;
}

sub addUserSet ($self) {
	my $new_user_set = $self->schema->resultset('UserSet')->addUserSet(
		params => {
			course_id => int($self->param('course_id')),
			set_id    => int($self->param('set_id')),
			%{ $self->req->json }
		}
	);
	$self->render(json => $new_user_set);
	return;
}

sub updateUserSet ($self) {
	my $updated_user_set = $self->schema->resultset('UserSet')->updateUserSet(
		info => {
			course_id      => int($self->param('course_id')),
			set_id         => int($self->param('set_id')),
			course_user_id => int($self->param("course_user_id"))
		},
		params => $self->req->json
	);
	$self->render(json => $updated_user_set);
	return;
}

sub deleteUserSet ($self) {
	my $updated_user_set = $self->schema->resultset('UserSet')->deleteUserSet(
		info => {
			course_id      => int($self->param('course_id')),
			set_id         => int($self->param('set_id')),
			course_user_id => int($self->param("course_user_id"))
		},
		params => $self->req->json
	);
	$self->render(json => $updated_user_set);
	return;
}

1;
