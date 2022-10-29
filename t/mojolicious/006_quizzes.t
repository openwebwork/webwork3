#!/usr/bin/env perl

use Test2::V0;
use Mojo::Base -signatures;
use Test2::MojoX;
use Mojo::File qw/curfile/;
use Mojo::JSON qw/decode_json/;
use Mojo::JSON qw/true false/;

use lib curfile->dirname->dirname->sibling('lib')->to_string;
use lib curfile->dirname->sibling('lib')->to_string;

use DBSubtest qw/mojoDBSubtest/;
use BuildDB qw/loadPermissions addCourses addUsers addSets/;

mojoDBSubtest 'course/sets routes for quizzes' => sub ($t, $schema) {
	# Add the neccessary sample data for the test.
	loadPermissions($schema, $t->app->home);
	addCourses($schema, $t->app->home);
	addUsers($schema, $t->app->home);
	addSets($schema, $t->app->home);

	# Login as an user with instructor privileges in a course (Arithmetic; course_id: 4)
	$t->post_ok('/webwork3/api/login' => json => { username => 'lisa', password => 'lisa' })->status_is(200)
		->content_type_is('application/json;charset=UTF-8')->json_is('/logged_in' => true)
		->json_is('/user/username' => 'lisa')->json_is('/user/is_admin' => false);

	# Load quiz sets from JSON file.
	my $course_quizzes = decode_json($t->app->home->child('t/db/sample_data/quizzes.json')->slurp);
	my @quizzes;
	for my $course_data (@$course_quizzes) {
		for my $quiz (@{ $course_data->{sets} }) {
			$quiz->{set_type}    = 'QUIZ';
			$quiz->{course_name} = $course_data->{course_name};
			push(@quizzes, $quiz);
		}
	}

	# Get all problem_sets
	$t->get_ok('/webwork3/api/courses/4/sets')->content_type_is('application/json;charset=UTF-8');
	my $all_problem_sets = $t->tx->res->json;

	# find the first quiz in the course.

	my $quiz1 = (grep { $_->{set_type} eq 'QUIZ' } @$all_problem_sets)[0];

	# test some things about this quiz
	$t->get_ok("/webwork3/api/courses/4/sets/$quiz1->{set_id}")->content_type_is('application/json;charset=UTF-8')
		->json_is('/set_name' => 'Quiz #1');

	# Test that booleans are returned correctly.

	$quiz1 = $t->tx->res->json;
	my $timed = $quiz1->{set_params}->{timed};
	ok($timed, 'testing that timed compares to 1.');
	is($timed, true, 'testing that timed compares to true');
	ok(JSON::PP::is_bool($timed),           'testing that timed is a true or false');
	ok(JSON::PP::is_bool($timed) && $timed, 'testing that timed is a true');

	# Make a new quiz

	my $new_quiz_params = {
		set_name   => 'Quiz #20',
		set_type   => 'QUIZ',
		set_params => { timed => true, quiz_duration => 30,  problem_randorder => true },
		set_dates  => { open  => 100,  due           => 200, answer            => 300 }
	};

	$t->post_ok('/webwork3/api/courses/4/sets' => json => $new_quiz_params)
		->content_type_is('application/json;charset=UTF-8')->json_is('/set_name' => 'Quiz #20')
		->json_is('/set_type' => 'QUIZ');
	my $returned_quiz = $t->tx->res->json;

	my $new_quiz          = $t->tx->res->json;
	my $problem_randorder = $new_quiz->{set_params}->{problem_randorder};
	ok($problem_randorder, 'testing that problem_randorder compares to 1.');
	is($problem_randorder, true, 'testing that problem_randorder compares to true');
	ok(JSON::PP::is_bool($problem_randorder), 'testing that problem_randorder is a true or false');
	ok(JSON::PP::is_bool($problem_randorder) && $problem_randorder, 'testing that problem_randorder is a true');

	# Check that updating a boolean parameter is working:

	$t->put_ok("/webwork3/api/courses/4/sets/$returned_quiz->{set_id}" => json =>
			{ set_params => { problem_randorder => false } })->status_is(200);

	my $updated_quiz = $t->tx->res->json;

	$problem_randorder = $updated_quiz->{set_params}->{problem_randorder};
	ok(!$problem_randorder, 'testing that hide_hint is falsy.');
	is($problem_randorder, false, 'testing that problem_randorder compares to false');
	ok(JSON::PP::is_bool($problem_randorder), 'testing that problem_randorder is a true or false');
	ok(JSON::PP::is_bool($problem_randorder) && !$problem_randorder, 'testing that problem_randorder is a false');

	# delete the added quiz
	$t->delete_ok("/webwork3/api/courses/4/sets/$returned_quiz->{set_id}")
		->content_type_is('application/json;charset=UTF-8')->json_is('/set_name' => 'Quiz #20')
		->json_is('/set_type' => 'QUIZ');
};

done_testing();
