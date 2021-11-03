package WeBWorK3::Controller::Problem;
use warnings;
use strict;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Data::Dumper;
use Try::Tiny;
use Mojo::JSON qw/true false/;

sub addProblem ($self) {
	my $course_set_params = {
		course_id => int($self->param("course_id")),
		set_id    => int($self->param("set_id"))
	};

	my $problem = $self->schema->resultset("Problem")->addSetProblem($course_set_params, $self->req->json);
	$self->render(json => $problem);
	return;
}

sub getAllProblems ($self) {
	my $course_info = {
		course_id => int($self->param("course_id"))
	};
	my @problems = $self->schema->resultset("Problem")->getProblems($course_info);
	$self->render(json => \@problems);
	return;
}

1;
