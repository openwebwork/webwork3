package WeBWorK3::Controller::ProblemSet;
use warnings;
use strict;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Data::Dumper;
use Try::Tiny;
use Mojo::JSON qw/true false/;

sub getAllProblemSets ($self) {
	my @all_problem_sets = $self->schema->resultset("ProblemSet")->getAllProblemSets;
	$self->render(json => \@all_problem_sets);
	return;
}

sub getProblemSets ($self) {
	my @problem_sets =
		$self->schema->resultset("ProblemSet")->getProblemSets({ course_id => int($self->param("course_id")) });
	# convert booleans
	for my $set (@problem_sets) {
		$set->{set_visible} = $set->{set_visible} ? true : false;
	}
	$self->render(json => \@problem_sets);
	return;
}

sub getProblemSet ($self) {
	my $problem_set = $self->schema->resultset("ProblemSet")->getProblemSet({
		course_id => int($self->param("course_id")),
		set_id    => int($self->param("set_id"))
	});
	$self->render(json => $problem_set);
	return;
}

## update the course given by course_id with given params

sub updateProblemSet ($self) {
	my $problem_set = $self->schema->resultset("ProblemSet")->updateProblemSet(
		{
			course_id => int($self->param("course_id")),
			set_id    => int($self->param("set_id"))
		},
		$self->req->json
	);
	$self->render(json => $problem_set);
	return;
}

sub addProblemSet ($self) {
	my $problem_set = $self->schema->resultset("ProblemSet")
		->addProblemSet({ course_id => int($self->param("course_id")) }, $self->req->json);
	$self->render(json => $problem_set);
	return;
}

sub deleteProblemSet ($self) {
	my $problem_set = $self->schema->resultset("ProblemSet")->deleteProblemSet({
		course_id => int($self->param("course_id")),
		set_id    => int($self->param("set_id"))
	});
	$self->render(json => $problem_set);
	return;
}

sub getUserSets ($self) {
	my @user_sets = $self->schema->resultset("UserSet")->getUserSetsForSet({
		course_id => int($self->param("course_id")),
		set_id    => int($self->param("set_id"))
	});
	$self->render(json => \@user_sets);
	return;
}

sub addUserSet ($self) {
	my $new_user_set = $self->schema->resultset("UserSet")->addUserSet(
		{
			course_id      => int($self->param("course_id")),
			set_id         => int($self->param("set_id")),
			course_user_id => $self->req->json->{course_user_id}
		},
		$self->req->json
	);
	$self->render(json => $new_user_set);
	return;
}

sub updateUserSet ($self) {
	my $updated_user_set = $self->schema->resultset("UserSet")->updateUserSet(
		{
			course_id      => int($self->param("course_id")),
			set_id         => int($self->param("set_id")),
			course_user_id => int($self->param("course_user_id"))
		},
		$self->req->json
	);
	$self->render(json => $updated_user_set);
	return;
}

sub deleteUserSet ($self) {
	my $updated_user_set = $self->schema->resultset("UserSet")->deleteUserSet(
		{
			course_id      => int($self->param("course_id")),
			set_id         => int($self->param("set_id")),
			course_user_id => int($self->param("course_user_id"))
		},
		$self->req->json
	);
	$self->render(json => $updated_user_set);
	return;
}

1;
