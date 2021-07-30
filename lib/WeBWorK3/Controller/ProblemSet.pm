package WeBWorK3::Controller::ProblemSet;
use warnings;
use strict;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Try::Tiny;

sub getProblemSets {
	my $self = shift;
	my @all_problem_sets =  $self->schema->resultset("ProblemSet")->getAllProblemSets;
	$self->render(json => \@all_problem_sets);
	return;
}

sub getProblemSet {
	my $self = shift;
	my $problem_set = $self->schema->resultset("ProblemSet")
		->getProblemSet({
				course_id => int( $self->param("course_id")),
				set_id => int( $self->param("set_id"))
			});
	$self->render(json => $problem_set);
	return;
}

## update the course given by course_id with given params

sub updateProblemSet {
	my $self = shift;
	my $problem_set = $self->schema->resultset("ProblemSet")
		->updateProblemSet( {
			course_id => int( $self->param("course_id")),
			set_id => int( $self->param("set_id"))
		},$self->req->json);
	$self->render(json => $problem_set);
	return;
}

sub addProblemSet {
	my $self = shift;
	my $problem_set = $self->schema->resultset("ProblemSet")
		->addProblemSet({course_id => int( $self->param("course_id"))}, $self->req->json);
	$self->render(json => $problem_set);
	return;
}

sub deleteProblemSet {
	my $self = shift;
	my $problem_set = $self->schema->resultset("ProblemSet")
		->deleteProblemSet( {
				course_id => int( $self->param("course_id")),
			set_id => int( $self->param("set_id"))
		});
	$self->render(json => $problem_set);
	return;
}


1;