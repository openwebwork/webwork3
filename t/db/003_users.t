#!/usr/bin/env perl

# This tests the basic database CRUD functions with courses.

use warnings;
use strict;

BEGIN {
	use File::Basename qw/dirname/;
	use Cwd qw/abs_path/;
	$main::ww3_dir = abs_path(dirname(__FILE__)) . '/../..';
}

use lib "$main::ww3_dir/lib";

use Test::More;
use Test::Exception;
use Clone qw/clone/;
use List::MoreUtils qw/firstval/;

use DB::Schema;
use DB::TestUtils qw/loadCSV removeIDs/;
use YAML qw/LoadFile/;
use DateTime::Format::Strptime;

# Load the database
my $config_file = "$main::ww3_dir/conf/ww3-dev.yml";
$config_file = "$main::ww3_dir/conf/ww3-dev.dist.yml" unless (-e $config_file);
my $config = LoadFile($config_file);
my $schema = DB::Schema->connect($config->{database_dsn}, $config->{database_user}, $config->{database_password});

my $strp   = DateTime::Format::Strptime->new(pattern => '%F', on_error => 'croak');

my $users_rs  = $schema->resultset("User");
my $course_rs = $schema->resultset("Course");

# Remove a few users if they exists in the database
my $users_to_remove = $users_rs->search({
	username => {
		'-in' => [ 'maggie', 'wiggam', 'selma', 'selma@google.com' ]
	}
});
$users_to_remove->delete_all if defined($users_to_remove);

# Get a list of users from the CSV file
my @students = loadCSV("$main::ww3_dir/t/db/sample_data/students.csv");

# Remove duplicates
my %seen = ();
@students = grep { !$seen{ $_->{username} }++ } @students;
for my $student (@students) {
	for my $key (qw/course_name recitation section params role/) {
		delete $student->{$key};
	}
	$student->{is_admin} = 0;
}

# Add the admin user
push(
	@students,
	{
		username   => "admin",
		email      => 'admin@google.com',
		is_admin   => 1,
		first_name => "Andrea",
		last_name  => "Administrator",
		student_id => undef
	}
);
my @all_students = sort { $a->{username} cmp $b->{username} } @students;

# Get a list of all users.
my @users_from_db = $users_rs->getAllGlobalUsers;
for my $user (@users_from_db) {
	removeIDs($user);
}
@users_from_db = sort { $a->{username} cmp $b->{username} } @users_from_db;
is_deeply(\@all_students, \@users_from_db, "getUsers: all users");

# Get a single user by username
my $user = $users_rs->getGlobalUser(info => { username => $all_students[0]->{username} });
removeIDs($user);
delete $user->{role};
is_deeply($all_students[0], $user, "getUser: by username");

# Get a single user by user_id
$user = $users_rs->getGlobalUser(info => { user_id => 2 });
removeIDs($user);
my @stud2 = grep { $_->{username} eq $user->{username} } @all_students;
is_deeply($stud2[0], $user, "getUser: by user_id");

# Get one user that does not exist
throws_ok {
	$user = $users_rs->getGlobalUser(info => { user_id => -9 });
}
"DB::Exception::UserNotFound", "getUser: undefined user_id";

throws_ok {
	$user = $users_rs->getGlobalUser(info => { username => "non_existent_user" });
}
"DB::Exception::UserNotFound", "getUser: undefined username";

# getUsers: Test that not passing either a course_id or course_name results in an error.
throws_ok {
	$users_rs->getCourseUsers(info => { my_course => "Precalculus" });
}
'DB::Exception::ParametersNeeded', "getUsers: course_name or course_id not passed in";

# Add one user
$user = {
	username   => "wiggam",
	last_name  => "Wiggam",
	first_name => "Clancy",
	email      => 'wiggam@springfieldpd.gov',
	student_id => '',
	is_admin   => 0,
};

my $new_user = $users_rs->addGlobalUser(params => $user);
removeIDs($new_user);
is_deeply($user, $new_user, "addUser: adding a user");

# Try to add a user without passing username info
throws_ok {
	$users_rs->addGlobalUser(
		params => {
			username_name => "selma",
			email         => 'selma@google.com'
		}
	);
}
"DB::Exception::ParametersNeeded", "addUser: wrong user_info sent";

# Check that adding a user with an invalid field throws an error
throws_ok {
	$users_rs->addGlobalUser(
		params => {
			username      => "selma",
			invalid_field => 1
		}
	);
}
qr/No such column 'invalid_field'/, "addUser: pass in an invalid field";

# Add a user with an invalid username
throws_ok {
	$users_rs->addGlobalUser(
		params => {
			username => "my name is selma",
			email    => 'selma@google.com'
		}
	);
}
"DB::Exception::InvalidParameter", "addUser: bad username sent";

# Check that using an email address for a username is valid:
# Add one user
my $user2 = {
	username   => 'selma@google.com',
	last_name  => "Bouvier",
	first_name => "Selma",
	email      => 'selma@google.com',
	student_id => '',
	is_admin   => 0,
};

my $added_user2 = $users_rs->addGlobalUser(params => $user2);
removeIDs($added_user2);
is_deeply($user2, $added_user2, "addUser: check that using an email for a username is valid.");

# Update a user
my $updated_user = clone $user;
$updated_user->{email} = 'spring.cop@gmail.com';
my $up_user_from_db = $users_rs->updateGlobalUser(
	info   => { username => $updated_user->{username} },
	params => $updated_user
);
removeIDs($up_user_from_db);
is_deeply($updated_user, $up_user_from_db, "updateUser: updating a user");

# Try to update a user without passing username info
throws_ok {
	$users_rs->updateGlobalUser(info => { username_name => "wiggam" }, params => $updated_user);
}
"DB::Exception::ParametersNeeded", "updateUser: wrong user_info sent";

# Try to update a user that doesn't exist
throws_ok {
	$users_rs->updateGlobalUser(info => { username => "non_existent_user" }, params => $updated_user);
}
"DB::Exception::UserNotFound", "updateUser: update user for a non-existing username";

throws_ok {
	$users_rs->updateGlobalUser(info => { user_id => -5 }, params => $updated_user);
}
"DB::Exception::UserNotFound", "updateUser: update user for a non-existing user_id";

# Check that updated an invalid field throws an error
throws_ok {
	$users_rs->updateGlobalUser(
		info => {
			username => "wiggam"
		},
		params => {
			invalid_field => 1
		}
	)
}
qr/No such column 'invalid_field'/, "updateUser: pass in an invalid field";

# Delete a user
my $user_to_delete = $users_rs->deleteGlobalUser(info => { username => $user->{username} });

delete $user_to_delete->{user_id};
is_deeply($updated_user, $user_to_delete, "deleteUser: delete a user");

# Delete a user that doesn't exist.
throws_ok {
	$user = $users_rs->deleteGlobalUser(info => { username => "undefined_username" });
}
"DB::Exception::UserNotFound", "deleteUser: trying to delete with undefined username";

throws_ok {
	$user = $users_rs->deleteGlobalUser(info => { user_id => -3 });
}
"DB::Exception::UserNotFound", "deleteUser: trying to delete with undefined user_id";

## get a list of courses for a user

my @user_courses = $course_rs->getUserCourses(info => { username => "lisa" });
for my $user_course (@user_courses) {
	removeIDs($user_course);
}

my @courses = loadCSV("$main::ww3_dir/t/db/sample_data/courses.csv");
for my $course (@courses) {
	for my $date (keys %{ $course->{course_dates} }) {
		my $dt = $strp->parse_datetime($course->{course_dates}->{$date});
		$course->{course_dates}->{$date} = $dt->epoch;
	}
}

@students = loadCSV("$main::ww3_dir/t/db/sample_data/students.csv");

my @user_courses_from_csv = grep { $_->{username} eq "lisa" } @students;

for my $user_course (@user_courses_from_csv) {
	my $course = firstval { $_->{course_name} eq $user_course->{course_name} } @courses;
	for my $key (qw/email first_name last_name username student_id/) {
		delete $user_course->{$key};
	}
	$user_course->{course_user_params} = $user_course->{params};
	delete $user_course->{params};
	$user_course->{visible}      = $course->{visible};
	$user_course->{course_dates} = $course->{course_dates};
}

is_deeply(\@user_courses, \@user_courses_from_csv, "getUserCourses: get all courses for a given user");

## try to get a list of course from a non-existent user

throws_ok {
	$course_rs->getUserCourses(info => { username => "non_existent_user" });
}
"DB::Exception::UserNotFound", "getUserCourses: try to get a list of courses for a non-existent user";

done_testing;

1;

