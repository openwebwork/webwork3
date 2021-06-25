package webwork3::Controller::ProblemSet;
use Mojo::Base 'Mojolicious::Controller', -signatures;

use Try::Tiny;
use Data::Dump qw/dd/;

sub getProblemSets {
	my $self = shift;
	my @all_problem_sets =  $self->schema->resultset("ProblemSet")->getAllProblemSets;
	$self->render(json => \@all_problem_sets);
}

sub getProblemSet {
	my $self = shift;
	# try {
		my $set = $self->schema->resultset("ProblemSet")
			->getProblemSet({
					course_id => int( $self->param("course_id")),
					set_id => int( $self->param("set_id"))
				});
		$self->render(json => $set);
	# } catch {
	# 	dd ref $_;
	# 	$self->render(json => {msg => "oops!", exception => ref($_)});
	# };
}

## update the course given by course_id with given params

sub updateProblemSet {
	my $self = shift;
	my $set = $self->schema->resultset("ProblemSet")
		->updateProblemSet( {
			course_id => int( $self->param("course_id")),
			set_id => int( $self->param("set_id"))
		},$self->req->json);
	$self->render(json => $set);
}

sub addProblemSet {
	my $self = shift;
	my $set = $self->schema->resultset("ProblemSet")
		->addProblemSet({course_id => int( $self->param("course_id"))}, $self->req->json);
	$self->render(json => $set);
}

sub deleteProblemSet {
	my $self = shift;
	my $set = $self->schema->resultset("ProblemSet")
		->deleteProblemSet( {
				course_id => int( $self->param("course_id")),
			set_id => int( $self->param("set_id"))
		});
	$self->render(json => $set);
}


1;