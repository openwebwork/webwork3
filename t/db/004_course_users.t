#!/usr/bin/env perl

# This tests the basic database CRUD functions of course users.

use warnings;
use strict;

BEGIN {
	use File::Basename qw/dirname/;
	use Cwd qw/abs_path/;
	$main::ww3_dir = abs_path(dirname(__FILE__)) . '/../..';
}

use lib "$main::ww3_dir/lib";
use lib "$main::ww3_dir/t/lib";

use Test2::V0;
use YAML::XS qw/LoadFile/;
use Clone qw/clone/;
use Mojo::JSON qw/false/;

use DB::Schema;
use TestUtils qw/loadCSV removeIDs/;

# Load the database
my $config_file = "$main::ww3_dir/conf/webwork3-test.yml";
$config_file = "$main::ww3_dir/conf/webwork3-test.dist.yml" unless (-e $config_file);
my $config = LoadFile($config_file);
my $schema = DB::Schema->connect(
	$config->{database_dsn},
	$config->{database_user},
	$config->{database_password},
	{ quote_names => 1 }
);

# $schema->storage->debug(1);  # print out the SQL commands.

my $user_rs = $schema->resultset('User');

# Get a list of users from the CSV file
my @students = loadCSV("$main::ww3_dir/t/db/sample_data/students.csv");
for my $student (@students) {
	$student->{is_admin}           = false;
	$student->{course_user_params} = $student->{params};
	delete $student->{params};
}

# Filter only precalc students
my @precalc_students = grep { $_->{course_name} eq 'Precalculus' } @students;
for my $student (@precalc_students) {
	delete $student->{course_name};
}
@precalc_students = sort { $a->{username} cmp $b->{username} } @precalc_students;

# Fetch all precalc users from the database.
my @precalc_users_from_db = $user_rs->getCourseUsers(info => { course_name => 'Precalculus' }, merged => 1);

@precalc_users_from_db = sort { $a->{username} cmp $b->{username} } @precalc_users_from_db;
removeIDs($_) for @precalc_users_from_db;

is(\@precalc_users_from_db, \@precalc_students, 'getUsers: get users from a course');

# getUsers: Test that an unknown course results in an error.
is(
	dies { $user_rs->getCourseUsers(info => { course_name => 'unknown_course' }); },
	check_isa('DB::Exception::CourseNotFound'),
	'getUsers: undefined course_name'
);

# getUsers: Test that an unknown course_id results in an error.
is(
	dies { $user_rs->getCourseUsers(info => { course_id => -3 }); },
	check_isa('DB::Exception::CourseNotFound'),
	'getUsers: undefined course_id'
);

# getUsers: Test that not passing either a course_id or course_name results in an error.
is(
	dies { $user_rs->getCourseUsers(info => { my_course => 'Precalculus' }); },
	check_isa('DB::Exception::ParametersNeeded'),
	'getUsers: course_name or course_id not passed in'
);

# Test getUser

my $user = $user_rs->getCourseUser(
	info => {
		course_name => 'Precalculus',
		username    => $precalc_students[0]->{username}
	},
	merged => 1
);
removeIDs($user);

is($user, $precalc_students[0], 'getCourseUser: get one merged user');

# getUser: Test that an unknown course results in an error
is(
	dies { $user_rs->getCourseUser(info => { course_name => 'unknown_course', username => 'barney' }); },
	check_isa('DB::Exception::CourseNotFound'),
	'getCourseUser: undefined course'
);

# getUser: Test that an unknown user results in an error
is(
	dies { $user_rs->getCourseUser(info => { course_name => 'Precalculus', username => 'unknown_user' }); },
	check_isa('DB::Exception::UserNotFound'),
	'getCourseUser: undefined user'
);

# getUser: Test that an existing user who is not in the course returns an error.
is(
	dies { $user_rs->getCourseUser(info => { course_name => 'Arithmetic', username => 'marge' }); },
	check_isa('DB::Exception::UserNotInCourse'),
	'getCourseUser: get a user that is not in the course'
);

# addUser: Add a user to a course
# Remove the following user if already defined in the course
my $quimby = $user_rs->find({
	'username' => 'quimby',
});
$quimby->delete if defined($quimby);

my $user_params = {
	username   => 'quimby',
	first_name => 'Joe',
	last_name  => 'Quimby',
	email      => 'mayor_joe@springfield.gov',
	student_id => '12345',
	is_admin   => false
};

my $course_user_params = {
	username           => 'quimby',
	role               => 'student',
	course_user_params => {},
	section            => undef,
	recitation         => undef,
};

$user_rs->addGlobalUser(params => $user_params);
$user = $user_rs->addCourseUser(
	info   => { course_name => 'Arithmetic', username => 'quimby' },
	params => $course_user_params
);
for my $key (qw/username course_name/) {
	delete $course_user_params->{$key};
}

removeIDs($user);
delete $user_params->{course_name};

is($user, $course_user_params, 'addCourseUser: add a user to a course');

# Check that adding a user returns a merged user.
my $quimby_db = $user_rs->addCourseUser(
	info   => { course_name => 'Precalculus', username => 'quimby' },
	params => $course_user_params,
	merged => 1
);
removeIDs($quimby_db);

my $quimby_params = clone($course_user_params);
for my $key (keys %$user_params) {
	$quimby_params->{$key} = $user_params->{$key};
}
is($quimby_db, $quimby_params, 'addCourseUser: check that an added user is returned merged');

# Checking that if the course exists, but the user is already a member an exception is thrown.
is(
	dies { $user_rs->addCourseUser(info => { course_name => 'unknown_course', username => 'barney' }); },
	check_isa('DB::Exception::CourseNotFound'),
	"addCourseUser: the course doesn't exist"
);

# updateUser:Check that the user updates.
my $updated_user = { params => { comment => 'Mayor Joe is the best!!' }, recitation => '2' };

is(
	dies { $user_rs->addCourseUser(info => { course_name => 'Arithmetic', username => 'moe' }); },
	check_isa('DB::Exception::UserAlreadyInCourse'),
	'addCourseUser: the user is already a member'
);

# try to add a non-existent user from a course:
is(
	dies { $user_rs->addCourseUser(info => { course_name => 'Arithmetic', username => 'non_existent_user' }) },
	check_isa('DB::Exception::UserNotFound'),
	'addCourseUser: try to add a non-existent user to a course'
);

# addCourseUser: add a user with undefined parameters
is(
	dies {
		$user_rs->addCourseUser(
			info   => { course_name => 'Topology', username        => 'quimby', },
			params => { role        => 'student',  undefined_field => 1 }
		);
	},
	check_isa('DBIx::Class::Exception'),
	'addCourseUser: an undefined field is passed in'
);

# Add a user with undefined course user parameters.
is(
	dies {
		$user_rs->addCourseUser(
			info   => { course_name => 'Topology', username           => 'quimby' },
			params => { role        => 'student',  course_user_params => { this_is_not_valid => 1 } }
		);
	},
	check_isa('DB::Exception::InvalidField'),
	'addCourseUser: an undefined parameter is set'
);

# Add a user with nonvalid fields
is(
	dies {
		$user_rs->addCourseUser(
			info   => { course_name => 'Topology', username           => 'quimby' },
			params => { role        => 'student',  course_user_params => { useMathQuill => 0 } }
		);
	},
	check_isa('DB::Exception::InvalidParameter'),
	'addCourseUser: an parameter with invalid value'
);

# Add a user with an invalid role
is(
	dies {
		$user_rs->addCourseUser(
			info   => { course_name => 'Topology', username => 'quimby' },
			params => { role        => 'cop' }
		);
	},
	check_isa('DB::Exception::UserRoleUndefined'),
	'addCourseUser: try to add a user with an undefined user role'
);

# updateCourseUser: check that the user updates.
$updated_user = {
	course_user_params => {
		comment => 'Mayor Joe is the best!!',
	},
	recitation => '2'
};

for my $key (keys %$updated_user) {
	$course_user_params->{$key} = $updated_user->{$key};
}

my $user_from_db = $user_rs->updateCourseUser(
	info   => { course_name => 'Arithmetic', username => 'quimby' },
	params => $updated_user
);

removeIDs($user_from_db);
is($user_from_db, $course_user_params, 'updateCourseUser: update a single user in an existing course.');

# updateCourseUser: check that if the course doesn't exist, an error is thrown:
is(
	dies {
		$user_rs->updateCourseUser(
			info   => { course_name => 'unknown_course', username => 'barney' },
			params => $updated_user
		);
	},
	check_isa('DB::Exception::CourseNotFound'),
	"updateCourseUser: the course doesn't exist"
);

# updateCourseUser: check that if the course exists, but the user not a member.
is(
	dies {
		$user_rs->updateCourseUser(
			info   => { course_name => 'Arithmetic', username => 'marge' },
			params => $updated_user
		);
	},
	check_isa('DB::Exception::UserNotInCourse'),
	'updateCourseUser: the user is not a member of the course'
);

# Try to add a non-existent user from a course.
is(
	dies {
		$user_rs->updateCourseUser(
			info   => { course_name => 'Arithmetic', user_name => 'bart' },
			params => $updated_user
		);
	},
	check_isa('DB::Exception::ParametersNeeded'),
	'updateCourseUser: the incorrect information is passed in.'
);

# Check that a non-existent course throws an error.
is(
	dies {
		$user_rs->updateCourseUser(
			info   => { course_name     => 'Arithmetic', username => 'quimby' },
			params => { sleeps_in_class => 1 }
		);
	},
	check_isa('DBIx::Class::Exception'),
	'updateCourseUser: an invalid field is set'
);

# updateCourseUser: update a user with undefined parameters
is(
	dies {
		$user_rs->updateCourseUser(
			info   => { course_name        => 'Arithmetic', username => 'quimby' },
			params => { course_user_params => { this_is_not_valid => 1 } }
		);
	},
	check_isa('DB::Exception::InvalidField'),
	'updateCourseUser: an undefined parameter is set'
);

# Check that updating a user with nonvalid fields throws an error.
is(
	dies {
		$user_rs->updateCourseUser(
			info   => { course_name        => 'Arithmetic', username => 'quimby' },
			params => { course_user_params => { useMathQuill => 'yes' } }
		);
	},
	check_isa('DB::Exception::InvalidParameter'),
	'updateCourseUser: an parameter with invalid value'
);

# Delete a single user from a course.
my $deleted_user;
my $dont_delete_users;    # Switch to not delete added users.

SKIP: {
	skip 'delete added users', 5 if $dont_delete_users;

	my $deleted_course_user = $user_rs->deleteCourseUser(info => { course_name => 'Arithmetic', username => 'quimby' });
	removeIDs($deleted_course_user);

	is($deleted_course_user, $course_user_params, 'deleteCourseUser: delete a user from a course');

	$deleted_user = $user_rs->deleteGlobalUser(info => { username => 'quimby' });
	removeIDs($deleted_user);

	is($deleted_user, $user_params, 'deleteGlobalUser: delete a user');

	# deleteUser: Check that if the course doesn't exist, an error is thrown:
	is(
		dies { $user_rs->deleteCourseUser(info => { course_name => 'unknown_course', username => 'barney' }); },
		check_isa('DB::Exception::CourseNotFound'),
		"deleteUser: the course doesn't exist"
	);

	# deleteUser: Check that if the course exists, but the user not a member.
	is(
		dies { $user_rs->deleteCourseUser(info => { course_name => 'Arithmetic', username => 'marge' }); },
		check_isa('DB::Exception::UserNotInCourse'),
		'deleteUser: the user is not a member of the course'
	);

	# deleteUser: Send in username_name instead of username
	is(
		dies { $user_rs->deleteCourseUser(info => { course_name => 'Arithmetic', username_name => 'bart' }); },
		check_isa('DB::Exception::ParametersNeeded'),
		'deleteUser: the incorrect information is passed in.'
	);
}

# Check that the precalc users have not changed.
@precalc_users_from_db = $user_rs->getCourseUsers(info => { course_name => 'Precalculus' }, merged => 1);

@precalc_users_from_db = sort { $a->{username} cmp $b->{username} } @precalc_users_from_db;
for (@precalc_users_from_db) { removeIDs($_); }

is(\@precalc_users_from_db, \@precalc_students, 'check: ensure that the precalc users in the database is restored.');

done_testing;
