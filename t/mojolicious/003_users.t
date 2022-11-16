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

mojoDBSubtest 'users routes' => sub ($t, $schema) {
	# Add the neccessary sample data for the test.
	loadPermissions($schema, $t->app->home);
	addCourses($schema, $t->app->home);
	addUsers($schema, $t->app->home);

	# Test all of the user routes with an admin user.
	$t->post_ok('/webwork3/api/login' => json => { username => 'admin', password => 'admin' })->status_is(200)
		->content_type_is('application/json;charset=UTF-8')->json_is('/logged_in' => true)
		->json_is('/user/user_id' => 1)->json_is('/user/is_admin' => true);

	my @all_users = $schema->resultset('User')->getAllGlobalUsers();

	$t->get_ok('/webwork3/api/users')->status_is(200)->content_type_is('application/json;charset=UTF-8')
		->json_is('/1/first_name' => $all_users[1]->{first_name})->json_is('/1/email' => $all_users[1]->{email});

	$t->get_ok('/webwork3/api/users/2')->status_is(200)->content_type_is('application/json;charset=UTF-8')
		->json_is('/username' => 'lisa')->json_is('/email' => 'lisa@google.com');

	# Add a new user.
	my $new_user = {
		email      => 'maggie@abc.com',
		first_name => 'Maggie',
		last_name  => 'Simpson',
		username   => 'maggie',
		student_id => '1234123423',
		is_admin   => false
	};

	$t->post_ok('/webwork3/api/users' => json => $new_user)->status_is(200)
		->content_type_is('application/json;charset=UTF-8')->json_is('/username' => $new_user->{username});

	# Extract the id from the response.
	my $new_user_from_db = $t->tx->res->json;

	$new_user->{user_id} = $new_user_from_db->{user_id};
	is($new_user_from_db, $new_user, 'addUser: global user added.');

	# Update the user.
	$new_user->{email} = 'maggie@juno.com';
	$t->put_ok("/webwork3/api/users/$new_user->{user_id}" => json => $new_user)->status_is(200);
	is($t->tx->res->json, $new_user, 'updateUser: global user updated');

	# Add the user to the course.
	my $added_user_to_course = { user_id => $new_user->{user_id}, role => 'student' };
	$t->post_ok('/webwork3/api/courses/4/users' => json => $added_user_to_course)->status_is(200)
		->content_type_is('application/json;charset=UTF-8')->json_is('/role' => 'student');

	my $lisa = (grep { $_->{username} eq 'lisa' } @all_users)[0];

	# Check if the user is a global user
	$t->get_ok('/webwork3/api/courses/1/users/lisa/exists')->status_is(200)
		->content_type_is('application/json;charset=UTF-8')->json_is('/first_name' => $lisa->{first_name});

	# Check if a non-existent user is a global user
	$t->get_ok('/webwork3/api/courses/1/users/non_existent_user/exists')->status_is(200)
		->content_type_is('application/json;charset=UTF-8');

	is($t->tx->res->json, {}, 'checkUserExists: check that a non-existent user returns {}');

	# Testing that booleans returned from the server are JSON booleans.
	# the first user is the admin

	my $admin_user = (grep { $_->{username} eq 'admin' } @all_users)[0];
	ok(not(JSON::PP::is_bool($admin_user->{user_id})), 'testing that $admin->{user_id} is not a JSON boolean');

	ok(!$new_user_from_db->{is_admin}, 'testing new_user->{is_admin} is not truthy.');
	is($new_user_from_db->{is_admin}, false, 'testing that new_user->{is_admin} compares to false');
	ok(JSON::PP::is_bool($new_user_from_db->{is_admin}), 'testing that new_user->{is_admin} is a true or false');
	ok(JSON::PP::is_bool($new_user_from_db->{is_admin}) && !$new_user_from_db->{is_admin},
		'testing that new_user->{is_admin} is a false');

	# Test for exceptions

	# Try to get a non-existent user.
	$t->get_ok('/webwork3/api/users/99999')->content_type_is('application/json;charset=UTF-8')
		->status_is(500, 'exception status')->json_is('/exception' => 'DB::Exception::UserNotFound');

	# Try to update a user not in a course.
	$t->put_ok('/webwork3/api/users/99999' => json => { email => 'fred@happy.com' })
		->status_is(500, 'exception status')->content_type_is('application/json;charset=UTF-8')
		->json_is('/exception' => 'DB::Exception::UserNotFound');

	# Try to add a user without a username.
	my $another_new_user = { username_name => 'this is the wrong field' };
	$t->post_ok('/webwork3/api/users' => json => $another_new_user)
		->content_type_is('application/json;charset=UTF-8')->status_is(500, 'exception status')
		->json_is('/exception' => 'DB::Exception::ParametersNeeded');

	# Try to delete a user not in a course.
	$t->delete_ok('/webwork3/api/users/99999')->content_type_is('application/json;charset=UTF-8')
		->status_is(500, 'exception status')->json_is('/exception' => 'DB::Exception::UserNotFound');

	# Add another user to a course that is not a global user.
	my $another_user = {
		username   => 'bob',
		first_name => 'Sideshow',
		last_name  => 'Bob',
		student_id => '933723',
		email      => 'bob@sideshow.net'
	};

	$t->post_ok('/webwork3/api/users' => json => $another_user)->status_is(200)
		->content_type_is('application/json;charset=UTF-8')->json_is('/username' => $another_user->{username});

	my $another_user_id = $t->tx->res->json('/user_id');

	$t->post_ok(
		'/webwork3/api/courses/4/users' => json => {
			user_id => $another_user_id,
			role    => 'student'
		}
	)->status_is(200)->content_type_is('application/json;charset=UTF-8');

	my $another_new_user_id = $t->tx->res->json('/user_id');

	# For cleanup, delete the created users.  Need to relogin as an admin:
	$t->delete_ok("/webwork3/api/users/$new_user_from_db->{user_id}")->status_is(200)
		->json_is('/username' => $new_user->{username});
	$t->delete_ok("/webwork3/api/users/$another_new_user_id")->status_is(200)
		->json_is('/username' => $another_user->{username});

	# Test that a non-admin user cannot access all of the routes
	# Logout the admin user and relogin as a non-admin.

	$t->post_ok('/webwork3/api/logout')->status_is(200)->json_is('/logged_in' => false);
	$t->post_ok('/webwork3/api/login' => json => { username => 'lisa', password => 'lisa' })->status_is(200)
		->content_type_is('application/json;charset=UTF-8')->json_is('/logged_in' => true)
		->json_is('/user/username' => 'lisa')->json_is('/user/is_admin' => false);

	$t->get_ok('/webwork3/api/users')->content_type_is('application/json;charset=UTF-8')->status_is(403)
		->json_is('/has_permission' => 0);

	$t->get_ok('/webwork3/api/users/1')->content_type_is('application/json;charset=UTF-8')->status_is(403)
		->json_is('/has_permission' => 0);

	$t->post_ok('/webwork3/api/users' => json => $new_user)->content_type_is('application/json;charset=UTF-8')
		->status_is(403)->json_is('/has_permission' => 0);

	$t->put_ok('/webwork3/api/users/1' => json => { email => 'lisa@aol.com' })->status_is(403)
		->content_type_is('application/json;charset=UTF-8')->json_is('/has_permission' => 0);

	$t->delete_ok('/webwork3/api/users/1')->content_type_is('application/json;charset=UTF-8')->status_is(403)
		->json_is('/has_permission' => 0);

	# Test that a user can access their own courses.  Lisa has user_id 2.
	$t->get_ok('/webwork3/api/users/2/courses')->status_is(200)->content_type_is('application/json;charset=UTF-8');

	# Relogin as the admin and delete the added users
	$t->post_ok('/webwork3/api/logout')->status_is(200)->json_is('/logged_in' => false);
	$t->post_ok('/webwork3/api/login' => json => { username => 'admin', password => 'admin' })->status_is(200);

	# The following routes test that global users can be handled by an instructor in the course
	# Lisa is an instructor in the Arithmetic course (course_id => 4)

	my $new_global_user = {
		username   => 'maggie',
		first_name => 'Maggie',
		last_name  => 'Simpson',
		student_id => 1234,
		email      => 'maggie@thesimpsons.tv'
	};

	$t->post_ok('/webwork3/api/courses/4/global-users' => json => $new_global_user)->status_is(200)
		->content_type_is('application/json;charset=UTF-8')->json_is('/username' => 'maggie');

	my $new_global_user_id = $t->tx->res->json('/user_id');

	$t->get_ok("/webwork3/api/courses/4/global-users/$new_global_user_id")->status_is(200)
		->content_type_is('application/json;charset=UTF-8')->json_is('/username' => 'maggie')
		->json_is('/student_id' => 1234);

	$t->put_ok("/webwork3/api/courses/4/global-users/$new_global_user_id" => json => { student_id => 4321 })
		->status_is(200)->content_type_is('application/json;charset=UTF-8')->json_is('/username' => 'maggie')
		->json_is('/student_id' => 4321);

	$t->delete_ok("/webwork3/api/courses/4/global-users/$new_global_user_id")->status_is(200)
		->content_type_is('application/json;charset=UTF-8');
};

done_testing;
