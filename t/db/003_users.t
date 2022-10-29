#!/usr/bin/env perl

# This tests the basic database CRUD functions with courses.

use Test2::V0;

# This must occur after Test2::V0 is loaded as that package enables all warnings.
use Mojo::Base -signatures;

use Mojo::File qw/curfile/;
use Mojo::JSON qw/decode_json true false/;

use lib curfile->dirname->dirname->sibling('lib')->to_string;
use lib curfile->dirname->sibling('lib')->to_string;

use BuildDB qw/loadPermissions addCourses addUsers/;
use DBSubtest qw/dbSubtest/;
use TestUtils qw/removeIDs cleanUndef/;

my $ww3_dir = curfile->dirname->dirname->dirname;

dbSubtest users => sub ($schema) {
	# Add the neccessary sample data to the database.
	loadPermissions($schema, $ww3_dir);
	addCourses($schema, $ww3_dir);
	addUsers($schema, $ww3_dir);

	my $users_rs  = $schema->resultset('User');
	my $course_rs = $schema->resultset('Course');

	# Get a list of users from the JSON file
	my $users = decode_json($ww3_dir->child('t/db/sample_data/users.json')->slurp);

	my @users;
	for my $user (@$users) {
		# Copy the users so the users.json file does not need to be read again.
		my $user_copy = {%$user};
		delete $user_copy->{courses};
		$user_copy->{is_admin} //= false;
		push(@users, $user_copy);
	}

	@users = sort { $a->{username} cmp $b->{username} } @users;

	# Get a list of all users.
	my @users_from_db = $users_rs->getAllGlobalUsers;
	for my $user (@users_from_db) {
		removeIDs($user);
		cleanUndef($user);
	}
	@users_from_db = sort { $a->{username} cmp $b->{username} } @users_from_db;
	is(\@users_from_db, \@users, 'getUsers: all users');

	# Get a single user by username
	my $user = $users_rs->getGlobalUser(info => { username => $users[0]->{username} });
	removeIDs($user);
	cleanUndef($user);
	is($user, $users[0], 'getUser: by username');

	# Get a single user by user_id
	$user = $users_rs->getGlobalUser(info => { user_id => 2 });
	removeIDs($user);
	my @stud2 = grep { $_->{username} eq $user->{username} } @users;
	is($user, $stud2[0], 'getUser: by user_id');

	# Get one user that does not exist
	is(
		dies { $user = $users_rs->getGlobalUser(info => { user_id => -9 }); },
		check_isa('DB::Exception::UserNotFound'),
		'getUser: undefined user_id'
	);

	is(
		dies { $user = $users_rs->getGlobalUser(info => { username => 'non_existent_user' }); },
		check_isa('DB::Exception::UserNotFound'),
		'getUser: undefined username'
	);

	# getUsers: Test that not passing either a course_id or course_name results in an error.
	is(
		dies { $users_rs->getCourseUsers(info => { my_course => 'Precalculus' }); },
		check_isa('DB::Exception::ParametersNeeded'),
		'getUsers: course_name or course_id not passed in'
	);

	# Add one user
	$user = {
		username   => 'wiggam',
		last_name  => 'Wiggam',
		first_name => 'Clancy',
		email      => 'wiggam@springfieldpd.gov',
		student_id => '',
		is_admin   => false,
	};

	my $new_user = $users_rs->addGlobalUser(params => $user);
	removeIDs($new_user);
	is($new_user, $user, 'addUser: adding a user');

	# Ensure that the default values are set
	my $patty_params = { username => 'patty' };
	my $patty        = $users_rs->addGlobalUser(params => $patty_params);
	removeIDs($patty);
	cleanUndef($patty);
	# the only default for users is { is_admin: false }
	$patty_params->{is_admin} = false;
	is($patty, $patty_params, 'addUser: check the default values from db.');

	# Try to add a user without passing username info
	is(
		dies {
			$users_rs->addGlobalUser(params => { username_name => 'selma', email => 'selma@google.com' });
		},
		check_isa('DB::Exception::ParametersNeeded'),
		'addUser: wrong user_info sent'
	);

	# Check that adding an invalid field ignores that field.

	my $selma_params = { username => 'selma', invalid_field => 1 };

	my $selma = $users_rs->addGlobalUser(params => $selma_params);
	removeIDs($selma);
	cleanUndef($selma);

	# cleanup params for comparison: invalid_field dropped, is_admin matches default
	delete $selma_params->{invalid_field};
	$selma_params->{is_admin} = false;
	is($selma, $selma_params, 'addUser: pass in an invalid field');

	# Add a user with an invalid username
	is(
		dies {
			$users_rs->addGlobalUser(params => { username => 'my name is selma', email => 'selma@google.com' });
		},
		check_isa('DB::Exception::InvalidParameter'),
		'addUser: bad username sent'
	);

	# Check that using an email address for a username is valid:
	# Add one user
	my $user2 = {
		username   => 'selma@google.com',
		last_name  => 'Bouvier',
		first_name => 'Selma',
		email      => 'selma@google.com',
		student_id => '',
		is_admin   => false,
	};

	my $added_user2 = $users_rs->addGlobalUser(params => $user2);
	removeIDs($added_user2);
	is($added_user2, $user2, 'addUser: check that using an email for a username is valid.');

	# Update a user
	my $updated_user = {%$user};
	$updated_user->{email} = 'spring.cop@gmail.com';
	my $updated_user_from_db = $users_rs->updateGlobalUser(
		info   => { username => $updated_user->{username} },
		params => $updated_user
	);
	removeIDs($updated_user_from_db);
	is($updated_user_from_db, $updated_user, 'updateUser: updating a user');

	# Try to update a user without passing username info
	is(
		dies {
			$users_rs->updateGlobalUser(info => { username_name => 'wiggam' }, params => $updated_user);
		},
		check_isa('DB::Exception::ParametersNeeded'),
		'updateUser: wrong user_info sent'
	);

	# Try to update a user that doesn't exist
	is(
		dies {
			$users_rs->updateGlobalUser(
				info   => { username => 'non_existent_user' },
				params => $updated_user
			);
		},
		check_isa('DB::Exception::UserNotFound'),
		'updateUser: update user for a non-existing username'
	);

	is(
		dies { $users_rs->updateGlobalUser(info => { user_id => -5 }, params => $updated_user); },
		check_isa('DB::Exception::UserNotFound'),
		'updateUser: update user for a non-existing user_id'
	);

	# Check that updated an invalid field throws an error
	like(
		dies {
			$users_rs->updateGlobalUser(info => { username => 'wiggam' }, params => { invalid_field => 1 })
		},
		qr/No such column 'invalid_field'/,
		'updateUser: pass in an invalid field'
	);

	# Delete users that were created
	my $user_to_delete = $users_rs->deleteGlobalUser(info => { username => $user->{username} });

	removeIDs($user_to_delete);
	cleanUndef($user_to_delete);
	is($user_to_delete, $updated_user, 'deleteUser: delete a user');

	my $deleted_selma = $users_rs->deleteGlobalUser(info => { username => 'selma' });
	removeIDs($deleted_selma);
	cleanUndef($deleted_selma);
	is($deleted_selma, $selma_params, 'deleteUser: deleter another user');

	my $deleted_patty = $users_rs->deleteGlobalUser(info => { username => 'patty' });
	removeIDs($deleted_patty);
	cleanUndef($deleted_patty);
	is($deleted_patty, $patty_params, 'deleteUser: deleter a third user');

	my $user_to_delete2 = $users_rs->deleteGlobalUser(info => { username => $added_user2->{username} });
	removeIDs($user_to_delete2);
	cleanUndef($user_to_delete2);
	is($user_to_delete2, $added_user2, 'deleteUser: delete yet another user.');

	# Delete a user that doesn't exist.
	is(
		dies { $user = $users_rs->deleteGlobalUser(info => { username => 'undefined_username' }); },
		check_isa('DB::Exception::UserNotFound'),
		'deleteUser: trying to delete with undefined username'
	);

	is(
		dies { $user = $users_rs->deleteGlobalUser(info => { user_id => -3 }); },
		check_isa('DB::Exception::UserNotFound'),
		'deleteUser: trying to delete with undefined user_id'
	);

	# Get the list of courses for a user
	my @user_courses = $course_rs->getUserCourses(info => { username => 'lisa' });
	for my $user_course (@user_courses) {
		removeIDs($user_course);
		cleanUndef($user_course);
	}

	my $courses = decode_json($ww3_dir->child('t/db/sample_data/courses.json')->slurp);

	my @user_courses_from_json;
	for my $user (@$users) {
		next unless $user->{username} eq 'lisa';
		for my $course_user_data (@{ $user->{courses} }) {
			my $course = (grep { $_->{course_name} eq $course_user_data->{course_name} } @$courses)[0];
			push(@user_courses_from_json, { %{ $course_user_data->{course_user} }, %$course });
			$user_courses_from_json[-1]{course_user_params} //= {};
			delete $user_courses_from_json[-1]{course_settings};
		}
	}

	# Make sure that the order of the courses is the same.
	@user_courses_from_json = sort { $a->{course_name} cmp $b->{course_name} } @user_courses_from_json;
	@user_courses           = sort { $a->{course_name} cmp $b->{course_name} } @user_courses;

	is(\@user_courses, \@user_courses_from_json, 'getUserCourses: get all courses for a given user');

	# Try to get a list of courses from a non-existent user.
	is(
		dies { $course_rs->getUserCourses(info => { username => 'non_existent_user' }); },
		check_isa('DB::Exception::UserNotFound'),
		'getUserCourses: try to get a list of courses for a non-existent user'
	);
};

done_testing;
