package WeBWorK3::Controller::Problem;
use warnings;
use strict;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Try::Tiny;
use Mojo::JSON qw/true false/;

sub addProblem ($self) {
	my $course_set_params = {
		course_id => int($self->param("course_id")),
		set_id    => int($self->param("set_id"))
	};
	my $problem_params = {
		params => {
			weight => 1,
			# TODO: finalize OPL DB and migrate away from paths
			# library_id      => $self->req->json->{id},
			problem_path => $self->req->json->{file_path}
		}
	};

	my $problem = $self->schema->resultset("Problem")->addSetProblem($course_set_params, $problem_params);
	$self->render(json => $problem);
	return;
}

1;
