package WeBWorK3::Controller::Problem;
use warnings;
use strict;

use Mojo::Base 'Mojolicious::Controller', -signatures;

sub getAllProblems ($c) {
	my @problems = $c->schema->resultset('SetProblem')->getProblems(
		info => {
			course_id => int($c->param('course_id'))
		}
	);
	$c->render(json => \@problems);
	return;
}

sub getProblem ($c) {
	my $problem = $c->schema->resultset('SetProblem')->getSetProblem(
		info => {
			course_id      => int($c->param('course_id')),
			set_id         => int($c->param('set_id')),
			set_problem_id => int($c->param('set_problem_id')),
		}
	);
	$c->render(json => $problem);
	return;
}

sub addProblem ($c) {
	my $problem = $c->schema->resultset('SetProblem')->addSetProblem(
		params => {
			course_id => int($c->param('course_id')),
			set_id    => int($c->param('set_id')),
			%{ $c->req->json }
		}
	);
	$c->render(json => $problem);
	return;
}

sub updateProblem ($c) {
	my $params = $c->req->json;
	# The render_params shouldn't be passed to the database, so delete that field
	delete $params->{render_params} if defined($params->{render_params});
	my $updated_problem = $c->schema->resultset('SetProblem')->updateSetProblem(
		info => {
			course_id      => int($c->param('course_id')),
			set_id         => int($c->param('set_id')),
			set_problem_id => int($c->param('set_problem_id'))
		},
		params => $params
	);
	$c->render(json => $updated_problem);
	return;
}

sub deleteProblem ($c) {
	my $deleted_problem = $c->schema->resultset('SetProblem')->deleteSetProblem(
		info => {
			course_id      => int($c->param('course_id')),
			set_id         => int($c->param('set_id')),
			set_problem_id => int($c->param('set_problem_id'))
		}
	);
	$c->render(json => $deleted_problem);
	return;
}

sub getUserProblemsForSet ($c) {
	my @user_problems = $c->schema->resultset('UserProblem')->getUserProblemsForSet(
		info => {
			course_id => int($c->param('course_id')),
			set_id    => int($c->param('set_id'))
		}
	);
	$c->render(json => \@user_problems);
	return;
}

sub getUserProblemsForUser ($c) {
	my @user_problems = $c->schema->resultset('UserProblem')->getUserProblemsForUser(
		info => {
			course_id => int($c->param('course_id')),
			user_id   => int($c->param('user_id'))
		}
	);
	$c->render(json => \@user_problems);
	return;
}

sub getUserProblem ($c) {
	my $user_problem = $c->schema->resultset('UserProblem')->getUserProblem(
		info => {
			course_id       => int($c->param('course_id')),
			user_problem_id => int($c->param('user_problem_id'))
		}
	);
	$c->render(json => $user_problem);
	return;
}

sub addUserProblem ($c) {
	my $problem_params = $c->req->json;

	# add the route parameters to the UserProblem to be added.
	$problem_params->{course_id} = int($c->param('course_id'))
		unless defined($problem_params->{course_id}) || defined($problem_params->{course_name});
	$problem_params->{set_id} = int($c->param('set_id'))
		unless $problem_params->{set_id} || $problem_params->{set_name};
	$problem_params->{user_id} = int($c->param('user_id'))
		unless defined($problem_params->{user_id}) || defined($problem_params->{username});

	# Only pass in set_id instead of set_name
	delete $problem_params->{set_name} if defined($problem_params->{set_id});

	# Only pass in user_id instead of username
	delete $problem_params->{username} if defined($problem_params->{user_id});

	# Only pass in problem_number or set_problem_id
	delete $problem_params->{set_problem_id}
		if (defined($problem_params->{set_problem_id}) && $problem_params->{set_problem_id} == 0);

	my $user_problem = $c->schema->resultset('UserProblem')->addUserProblem(params => $problem_params);
	$c->render(json => $user_problem);
	return;
}

sub updateUserProblem ($c) {
	my $problem_params = $c->req->json;

	my $user_problem = $c->schema->resultset('UserProblem')->updateUserProblem(
		info => {
			course_id       => int($c->param('course_id')),
			set_id          => int($c->param('set_id')),
			user_id         => int($c->param('user_id')),
			user_problem_id => int($c->param('user_problem_id'))
		},
		params => $problem_params
	);
	$c->render(json => $user_problem);
	return;
}

sub deleteUserProblem ($c) {
	my $deleted_problem = $c->schema->resultset('UserProblem')->deleteUserProblem(
		info => {
			course_id       => int($c->param('course_id')),
			set_id          => int($c->param('set_id')),
			user_id         => int($c->param('user_id')),
			user_problem_id => int($c->param('user_problem_id'))
		}
	);
	$c->render(json => $deleted_problem);
	return;
}

# ProblemPool routes

sub getAllProblemPools ($c) {
	my @problem_pools = $c->schema->resultset('ProblemPool')->getAllProblemPools;
	$c->render(json => \@problem_pools);
	return;
}

sub getProblemPools ($c) {
	my @problem_pools = $c->schema->resultset('ProblemPool')->getProblemPools(
		info => {
			course_id => int($c->param('course_id'))
		}
	);
	$c->render(json => \@problem_pools);
	return;
}

sub getProblemPool ($c) {
	my $problem_pool = $c->schema->resultset('ProblemPool')->getProblemPool(
		info => {
			course_id       => int($c->param('course_id')),
			problem_pool_id => int($c->param('problem_pool_id'))
		}
	);
	$c->render(json => $problem_pool);
	return;
}

sub addProblemPool ($c) {
	my $pool_params = $c->req->json;
	$pool_params->{course_id} = int($c->param('course_id'));
	my $problem_pool = $c->schema->resultset('ProblemPool')->addProblemPool(params => $pool_params);
	$c->render(json => $problem_pool);
	return;
}

sub updateProblemPool ($c) {
	my $problem_pool = $c->schema->resultset('ProblemPool')->updateProblemPool(
		info => {
			course_id       => int($c->param('course_id')),
			problem_pool_id => int($c->param('problem_pool_id')),
		},
		params => $c->req->json
	);
	$c->render(json => $problem_pool);
	return;
}

sub deleteProblemPool ($c) {
	my $problem_pool = $c->schema->resultset('ProblemPool')->deleteProblemPool(
		info => {
			course_id       => int($c->param('course_id')),
			problem_pool_id => int($c->param('problem_pool_id')),
		},
		params => $c->req->json
	);
	$c->render(json => $problem_pool);
	return;
}

# Pool Problem routes

sub getPoolProblems ($c) {
	# print $c->dumper($c->stash{'mojo.captures'});
	my @pool_problems = $c->schema->resultset('ProblemPool')->getPoolProblems(
		info => {
			course_id => int($c->param('course_id')),
			problem_pool_id => int($c->param('problem_pool_id'))
		}
	);
	$c->render(json => \@pool_problems);
	return;
}

sub getPoolProblem ($c) {
	my $problem_pool = $c->schema->resultset('ProblemPool')->getProblemPool(
		info => {
			course_id       => int($c->param('course_id')),
			problem_pool_id => int($c->param('problem_pool_id'))
		}
	);
	$c->render(json => $problem_pool);
	return;
}

sub addPoolProblem ($c) {
	my $pool_params = $c->req->json;
	$pool_params->{course_id} = int($c->param('course_id'));
	my $problem_pool = $c->schema->resultset('ProblemPool')->addProblemPool(params => $pool_params);
	$c->render(json => $problem_pool);
	return;
}

sub updatePoolProblem ($c) {
	my $problem_pool = $c->schema->resultset('ProblemPool')->updateProblemPool(
		info => {
			course_id       => int($c->param('course_id')),
			problem_pool_id => int($c->param('problem_pool_id')),
		},
		params => $c->req->json
	);
	$c->render(json => $problem_pool);
	return;
}

sub removePoolProblem ($c) {
	my $problem_pool = $c->schema->resultset('ProblemPool')->deleteProblemPool(
		info => {
			course_id       => int($c->param('course_id')),
			problem_pool_id => int($c->param('problem_pool_id')),
		},
		params => $c->req->json
	);
	$c->render(json => $problem_pool);
	return;
}

1;
