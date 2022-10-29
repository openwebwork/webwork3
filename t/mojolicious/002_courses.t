#!/usr/bin/env perl

use Test2::V0;
use Mojo::Base -signatures;
use Test2::MojoX;
use Mojo::File qw/curfile/;
use Mojo::JSON qw/true false/;

use lib curfile->dirname->dirname->sibling('lib')->to_string;
use lib curfile->dirname->sibling('lib')->to_string;

use DBSubtest qw/mojoDBSubtest/;
use BuildDB qw/loadPermissions addCourses addUsers/;

mojoDBSubtest 'courses routes' => sub ($t, $schema) {
	# Add the neccessary sample data for the test.
	loadPermissions($schema, $t->app->home);
	addCourses($schema, $t->app->home);
	addUsers($schema, $t->app->home);

	# Authenticate with the admin user.
	$t->post_ok('/webwork3/api/login' => json => { username => 'admin', password => 'admin' })->status_is(200)
		->content_type_is('application/json;charset=UTF-8')->json_is('/logged_in' => true)
		->json_is('/user/user_id' => 1)->json_is('/user/is_admin' => true);

	$t->get_ok('/webwork3/api/courses')->content_type_is('application/json;charset=UTF-8')
		->json_is('/0/course_name' => 'Precalculus')->json_is('/0/visible' => true);

	$t->get_ok('/webwork3/api/courses/1')->content_type_is('application/json;charset=UTF-8')
		->json_is('/course_name' => 'Precalculus')->json_is('/visible' => true);

	# Add a new course
	my $new_course = {
		course_name  => 'Linear Algebra',
		course_dates => { start => '2021-05-31', end => '2021-07-01' }
	};

	$t->post_ok('/webwork3/api/courses' => json => $new_course)->status_is(200)
		->json_is('/course_name' => $new_course->{course_name});

	# Extract the id from the response.
	my $new_course_id = $t->tx->res->json('/course_id');

	$new_course->{course_id} = $new_course_id;
	# The default for visible is true:
	$new_course->{visible} = true;
	is($t->tx->res->json, $new_course, "addCourse: courses match");

	# Update the course
	$new_course->{visible} = true;
	$t->put_ok("/webwork3/api/courses/$new_course_id" => json => $new_course)->status_is(200)
		->json_is('/course_name' => $new_course->{course_name});

	is($t->tx->res->json, $new_course, 'updateCourse: courses match');

	# Testing that booleans returned from the server are JSON booleans.
	# getting the first course

	# to check this, relogin as admin
	$t->post_ok('/webwork3/api/logout')->status_is(200);
	$t->post_ok('/webwork3/api/login' => json => { username => 'admin', password => 'admin' })->status_is(200);

	$t->get_ok('/webwork3/api/courses/1')->json_is('/course_name', 'Precalculus');
	my $precalc = $t->tx->res->json;

	ok($precalc->{visible}, 'Testing that visible field is truthy.');
	is($precalc->{visible}, true, 'Testing that the visible field compares to JSON::true');
	ok(JSON::PP::is_bool($precalc->{visible}), 'Testing that the visible field is a JSON boolean');
	ok(JSON::PP::is_bool($precalc->{visible}) && $precalc->{visible},
		'testing that the visible field is a JSON::true');

	ok(not(JSON::PP::is_bool($precalc->{course_id})), 'testing that $precalc->{visible} is not a JSON boolean');

	# Test for exceptions

	# A set that is not in a course.
	$t->get_ok('/webwork3/api/courses/99999')->status_is(500, 'error status')
		->content_type_is('application/json;charset=UTF-8')->json_is('/exception' => 'DB::Exception::CourseNotFound');

	# Try to update a non-existent course
	$t->put_ok('/webwork3/api/courses/999999' => json => { course_name => 'new course name' })
		->status_is(500, 'error status')->content_type_is('application/json;charset=UTF-8')
		->json_is('/exception' => 'DB::Exception::CourseNotFound');

	# Try to add a course without a course_name.
	my $another_new_course = { name => 'this is the wrong field' };

	$t->post_ok('/webwork3/api/courses/' => json => $another_new_course)->status_is(500, 'error status')
		->content_type_is('application/json;charset=UTF-8')->json_is('/exception' => 'DB::Exception::ParametersNeeded');

	# Try to delete a non-existent course.
	$t->delete_ok('/webwork3/api/courses/9999999')->status_is(500, 'error status')
		->content_type_is('application/json;charset=UTF-8')->json_is('/exception' => 'DB::Exception::CourseNotFound');

	# Delete the added course.
	$t->delete_ok("/webwork3/api/courses/$new_course_id")->status_is(200)
		->json_is('/course_name' => $new_course->{course_name});

	# Logout of the admin user account and relogin as a non-admin:
	$t->post_ok('/webwork3/api/logout')->status_is(200);
	$t->post_ok('/webwork3/api/login' => json => { username => 'lisa', password => 'lisa' })->status_is(200)
		->status_is(200)->json_is('/logged_in' => true)->json_is('/user/username' => 'lisa')
		->json_is('/user/is_admin' => false);

	# an instructor can get information about the given course.
	$t->get_ok('/webwork3/api/courses/4')->status_is(200)->json_is('/course_name' => 'Arithmetic');

	# and also the settings for the course.
	$t->get_ok('/webwork3/api/courses/4/default_settings')->status_is(200)
		->content_type_is('application/json;charset=UTF-8');
	$t->get_ok('/webwork3/api/courses/4/settings')->status_is(200)
		->content_type_is('application/json;charset=UTF-8');

	# The user with role instructor should not have permissions for the following routes.
	$t->post_ok('/webwork3/api/courses' => json => $new_course)->status_is(403)->json_is('/has_permission' => 0);

	$t->put_ok('/webwork3/api/courses/4' => json => { course_name => 'XXX' })->status_is(403)
		->json_is('/has_permission' => 0);

	$t->delete_ok('/webwork3/api/courses/4')->status_is(403)->json_is('/has_permission' => 0);
};

done_testing;
