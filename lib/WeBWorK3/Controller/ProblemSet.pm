package WeBWorK3::Controller::ProblemSet;
use warnings;
use strict;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Data::Dumper;
use Try::Tiny;

use Mojo::JSON qw/true false/;
use Mojo::Log;
use Data::Dumper;

my $log = Mojo::Log->new;

sub getAllProblemSets {
	my $self = shift;
	my @all_problem_sets =  $self->schema->resultset("ProblemSet")->getAllProblemSets;
	$self->render(json => \@all_problem_sets);
	return;
}

sub getProblemSets {
	my $self = shift;
	# $log->debug($self->param("course_id"));
	my @problem_sets = $self->schema->resultset("ProblemSet")
		->getProblemSets({ course_id => int($self->param("course_id")) });
	# convert booleans
	for my $set (@problem_sets) {
		# $log->debug(Dumper($set));
		$set->{set_visible} = $set->{set_visible} ? true : false;
	}
	$self->render(json => \@problem_sets);
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
