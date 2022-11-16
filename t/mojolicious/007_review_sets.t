#!/usr/bin/env perl

use Test2::V0;
use Mojo::Base -signatures;
use Test2::MojoX;
use Mojo::File qw/curfile/;
use Mojo::JSON qw/decode_json true false/;

use lib curfile->dirname->dirname->sibling('lib')->to_string;
use lib curfile->dirname->sibling('lib')->to_string;

use DBSubtest qw/mojoDBSubtest/;
use BuildDB qw/loadPermissions addCourses addUsers addSets/;

mojoDBSubtest 'course/sets routes for review sets' => sub ($t, $schema) {
	# Add the neccessary sample data for the test.
	loadPermissions($schema, $t->app->home);
	addCourses($schema, $t->app->home);
	addUsers($schema, $t->app->home);
	addSets($schema, $t->app->home);

	# Login as an user with instructor privileges in a course (Arithmetic; course_id: 4)
	$t->post_ok('/webwork3/api/login' => json => { username => 'lisa', password => 'lisa' })->status_is(200)
		->content_type_is('application/json;charset=UTF-8')->json_is('/logged_in' => true)
		->json_is('/user/username' => 'lisa')->json_is('/user/is_admin' => false);

	# Load review sets from JSON file.
	my $course_review_sets = decode_json($t->app->home->child('t/db/sample_data/review_sets.json')->slurp);
	my @review_sets;
	for my $course_data (@$course_review_sets) {
		for my $review_set (@{ $course_data->{sets} }) {
			$review_set->{set_type}    = 'REVIEW';
			$review_set->{course_name} = $course_data->{course_name};
			push(@review_sets, $review_set);
		}
	}

	# Get all problem_sets
	$t->get_ok('/webwork3/api/courses/4/sets')->content_type_is('application/json;charset=UTF-8');
	my $all_problem_sets = $t->tx->res->json;

	# find the first review set in the course.
	my $review_set1 = (grep { $_->{set_type} eq 'REVIEW' } @$all_problem_sets)[0];

	# test some things about this review set

	$t->get_ok("/webwork3/api/courses/4/sets/$review_set1->{set_id}")->status_is(200)
		->json_is('/set_name' => $review_set1->{set_name});

	# Test that booleans are returned correctly.

	$review_set1 = $t->tx->res->json;

	# The parameter can_retake should be false.
	my $can_retake = $review_set1->{set_params}->{can_retake};
	ok(!$can_retake, 'testing that can_retake compares to 0.');
	is($can_retake, false, 'testing that can_retake compares to Mojo::JSON::false');
	ok(JSON::PP::is_bool($can_retake), 'testing that can_retake is a Mojo::JSON::true or Mojo::JSON::false');
	ok(JSON::PP::is_bool($can_retake) && !$can_retake, 'testing that can_retake is a Mojo::JSON::true');

	# Make a new review set.
	$t->post_ok(
		'/webwork3/api/courses/4/sets' => json => {
			set_name   => 'Review #20',
			set_type   => 'REVIEW',
			set_params => { can_retake => true, },
			set_dates  => { open       => 100, closed => 200 }
		}
	)->content_type_is('application/json;charset=UTF-8')->json_is('/set_name' => 'Review #20')
		->json_is('/set_type' => 'REVIEW');

	$review_set1 = $t->tx->res->json;
	$can_retake  = $review_set1->{set_params}->{can_retake};
	ok($can_retake, 'testing that can_retake compares to 1.');
	is($can_retake, true, 'testing that can_retake compares to Mojo::JSON::true');
	ok(JSON::PP::is_bool($can_retake), 'testing that can_retake is a Mojo::JSON::true or Mojo::JSON::false');
	ok(JSON::PP::is_bool($can_retake) && $can_retake, 'testing that can_retake is a Mojo::JSON::true');

	# Check that updating a boolean parameter is working:
	$t->put_ok(
		"/webwork3/api/courses/4/sets/$review_set1->{set_id}" => json => { set_params => { can_retake => false } })
		->content_type_is('application/json;charset=UTF-8');

	my $updated_set = $t->tx->res->json;
	$can_retake = $updated_set->{set_params}->{can_retake};
	ok(!$can_retake, 'testing that can_retake is falsy.');
	is($can_retake, false, 'testing that can_retake compares to Mojo::JSON::false');
	ok(JSON::PP::is_bool($can_retake), 'testing that can_retake is a Mojo::JSON::true or Mojo::JSON::false');
	ok(JSON::PP::is_bool($can_retake) && !$can_retake, 'testing that can_retake is a Mojo::JSON::false');

	# delete the added review set
	$t->delete_ok("/webwork3/api/courses/4/sets/$review_set1->{set_id}")
		->content_type_is('application/json;charset=UTF-8')->json_is('/set_type' => 'REVIEW')
		->json_is('/set_name' => 'Review #20');
};

done_testing();
