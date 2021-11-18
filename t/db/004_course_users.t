#!/usr/bin/env perl
#
# This tests the basic database CRUD functions of course users.
#
use warnings;
use strict;

BEGIN {
	use File::Basename qw/dirname/;
	use Cwd qw/abs_path/;
	$main::ww3_dir = abs_path(dirname(__FILE__)) . '/../..';
}

use lib "$main::ww3_dir/lib";

use Text::CSV qw/csv/;
use Data::Dumper;
use List::Util qw(uniq);
use Test::More;
use Test::Exception;
use Try::Tiny;
use YAML::XS qw/LoadFile/;

use DB::WithParams;
use DB::WithDates;
use DB::Schema;
use DB::TestUtils qw/loadCSV removeIDs loadSchema/;
use DB::Utils qw/removeLoginParams/;

my $config;
my $config_file = "$main::ww3_dir/conf/ww3-dev.yml";
if (-e $config_file) {
	$config = LoadFile($config_file);
} else {
	die "The file $config_file does not exist.  Did you make a copy of it from ww3-dev.dist.yml ?";
}

my $schema =
	DB::Schema->connect($config->{test_database_dsn}, $config->{database_user}, $config->{database_password});

# $schema->storage->debug(1);  # print out the SQL commands.

my $course_rs = $schema->resultset("Course");
my $user_rs   = $schema->resultset("User");
my $cu_rs     = $schema->resultset("CourseUser");

## get a list of users from the CSV file
my @students = loadCSV("$main::ww3_dir/t/db/sample_data/students.csv");
for my $student (@students) {
	$student->{is_admin} = 0;
}

## filter only precalc students
my @precalc_students = grep { $_->{course_name} eq "Precalculus" } @students;
for my $student (@precalc_students) {
	delete $student->{course_name};
}
@precalc_students = sort { $a->{username} cmp $b->{username} } @precalc_students;

## get the course_id for Precalc

my $precalc = $course_rs->getCourse({ course_name => "Precalculus" });

## test getUsers

my @results = $user_rs->search(
	{
		'course_users.course_id' => $precalc->{course_id}
	},
	{
		prefetch => ["course_users"]
	}
);
my @users = map {
	removeLoginParams({
		$_->get_columns, $_->course_users->first->get_columns,
		params => $_->course_users->first->get_inflated_column("params")
	});
} @results;

my @precalc_students_from_db = sort { $a->{username} cmp $b->{username} } @users;
my $precalc_students_from_db = removeCourseUserIDs(\@precalc_students_from_db);

sub removeCourseUserIDs {
	my $users = shift;
	for my $user (@$users) {
		removeIDs($user);
	}
	return;
}

is_deeply(\@precalc_students, \@precalc_students_from_db, "getUsers: get users from a course");

## getUsers: test that an unknown course results in an error

throws_ok {
	$user_rs->getCourseUsers({ course_name => "unknown_course" });
}
'DB::Exception::CourseNotFound', "getUsers: undefined course_name";

throws_ok {
	$user_rs->getCourseUsers({ course_id => -3 });
}
'DB::Exception::CourseNotFound', "getUsers: undefined course_id";

## test getUser

my $user = $user_rs->getUser({ course_name => "Precalculus", username => $precalc_students[0]->{username} });
removeIDs($user);
is_deeply($precalc_students[0], $user, "getUser: get one user");

## getUser: test that an unknown course results in an error

throws_ok {
	$user_rs->getUser({ course_name => "unknown_course", username => "barney" });
}
'DB::Exception::CourseNotFound', "getUser: undefined course";

## getUser: test that an unknown user results in an error

throws_ok {
	$user_rs->getUser({ course_name => "Precalculus", username => "unknown_user" });
}
'DB::Exception::UserNotInCourse', "getUser: undefined user";

## getUser: test that an existing user who is not in the course returns an error.

throws_ok {
	$user_rs->getUser({ course_name => "Arithmetic", username => "marge" });
}
'DB::Exception::UserNotInCourse', "getUser: get a user that is not in the course";

## addUser:  add a user to a course

# remove the following user if already defined in the course

my $arithmetic = $course_rs->find({ course_name => "Arithmetic" });
my $quimby     = $user_rs->find({ username => "quimby" });
# warn Dumper {$quimby->get_inflated_columns} if $quimby;
if (defined($quimby)) {
	$quimby->delete;
	my $cu =
		$schema->resultset("CourseUser")->find({ user_id => $quimby->user_id, course_id => $arithmetic->course_id });
	$cu->delete if defined($cu);
}
# warn Dumper {$cu->get_inflated_columns} if $cu;

my $user_params = {
	username   => "quimby",
	first_name => "Joe",
	last_name  => "Quimby",
	email      => 'mayor_joe@springfield.gov',
	student_id => "12345",
	is_admin   => 0
};
my $course_user_params = {
	course_name => "Arithmetic",
	username    => "quimby",
	role        => "student",
	params      => {},
	recitation  => undef,
	section     => undef
};
$user_rs->addGlobalUser($user_params);
$user = $user_rs->addCourseUser($course_user_params);
for my $key (qw/username course_name/) {
	delete $course_user_params->{$key};
}

removeIDs($user);
delete $user_params->{course_name};

is_deeply($course_user_params, $user, "addUser: add a user to a course");

## addUser: check that if the course doesn't exist, an error is thrown:

throws_ok {
	$user_rs->addCourseUser({ course_name => "unknown_course", username => "barney" }, {});
}
"DB::Exception::CourseNotFound", "addUser: the course doesn't exist";

## addUser: the course exists, but the user is already a member.

throws_ok {
	$user_rs->addCourseUser({ course_name => "Arithmetic", username => "moe" });
}
"DB::Exception::UserAlreadyInCourse", "addUser: the user is already a member";

## updateUser: check that the user updates.

my $updated_user = { params => { comment => 'Mayor Joe is the best!!' }, recitation => "2" };

for my $key (keys %$updated_user) {
	$course_user_params->{$key} = $updated_user->{$key};
}

my $user_from_db = $user_rs->updateCourseUser({ course_name => 'Arithmetic', username => 'quimby' }, $updated_user);

removeIDs($user_from_db);
is_deeply($course_user_params, $user_from_db, "updateUser: update a single user in an existing course.");

## updateUser: check that if the course doesn't exist, an error is thrown:
throws_ok {
	$user_rs->updateCourseUser({ course_name => "unknown_course", username => "barney" }, $updated_user);
}
"DB::Exception::CourseNotFound", "updateUser: the course doesn't exist";

## updateUser: check that if the course exists, but the user not a member.
throws_ok {
	$user_rs->updateCourseUser({ course_name => "Arithmetic", username => "marge" }, $updated_user);
}
"DB::Exception::UserNotInCourse", "updateUser: the user is not a member of the course";

## updateUser: send in wrong information

throws_ok {
	$user_rs->updateCourseUser({ course_name => "Arithmetic", username_name => "bart" }, $updated_user);
}
"DB::Exception::ParametersNeeded", "updateUser: the incorrect information is passed in.";

## updateUser: update a user with nonvalid fields

throws_ok {
	$user_rs->updateCourseUser({ course_name => "Arithmetic", username => "quimby" }, { sleeps_in_class => 1 });
}
"DBIx::Class::Exception", "updateUser: an invalid field is set";

# These next test add a course user where both the course and user exist, but the user is
# not in the course.

my $course_user = {
	username    => "apu",
	course_name => "Arithmetic",
	role        => "instructor",
	params      => {},
	recitation  => undef,
	section     => undef
};

throws_ok {
	$user_rs->getCourseUser({ username => $course_user->{username}, course_name => $course_user->{course_name} });
}
"DB::Exception::UserNotInCourse", "getCourseUser: the user is not in the course";

my $course_user_from_db = $user_rs->addCourseUser($course_user);
removeIDs($course_user_from_db);

for my $key (qw/username course_name/) {
	delete $course_user->{$key};
}

is_deeply($course_user, $course_user_from_db, "addCourseUser: successfully adding a course user");

# try to add a non-existent user from a course:

throws_ok {
	$user_rs->addCourseUser({ course_name => "Arithmetic", username => "non_existent_user" })
}
"DB::Exception::UserNotFound", "getCourseUser: try to add a non-existent user to a course";

# check that a non-existent course throws an error:

throws_ok {
	$user_rs->addCourseUser({ course_name => "non_existent_course", username => "bart" })
}
"DB::Exception::CourseNotFound", "getCourseUser: try to add a user to a non-existent course";

## TODO: check that adding non-valid parameters throw errors.

$course_user->{recitation} = "2";

my $course_user3 = $user_rs->updateCourseUser(
	{
		username    => "apu",
		course_name => "Arithmetic"
	},
	{ recitation => "2" }
);

removeIDs($course_user3);
is_deeply($course_user3, $course_user, "updateCourseUser: update a field");

## delete a course user

my $course_user_to_delete = $user_rs->deleteCourseUser({
	username    => "apu",
	course_name => "Arithmetic",
});
removeIDs($course_user_to_delete);
is_deeply($course_user_to_delete, $course_user, "deleteCourseUser: delete a course user");

## deleteUser: delete a single user from a course

my $deleted_user;

my $dont_delete_users;    # switch to not delete added users.

SKIP: {

	skip "delete added users", 5 if $dont_delete_users;

	my $deleted_course_user = $user_rs->deleteCourseUser({ course_name => "Arithmetic", username => "quimby" });
	removeIDs($deleted_course_user);

	is_deeply($course_user_params, $deleted_course_user, 'deleteCourseUser: delete a user from a course');

	$deleted_user = $user_rs->deleteGlobalUser({ username => "quimby" });
	removeIDs($deleted_user);

	is_deeply($user_params, $deleted_user, "deleteGlobalUser: delete a user");

## deleteUser: check that if the course doesn't exist, an error is thrown:

	throws_ok {
		$user_rs->deleteCourseUser({ course_name => "unknown_course", username => "barney" });
	}
	"DB::Exception::CourseNotFound", "deleteUser: the course doesn't exist";

## deleteUser: check that if the course exists, but the user not a member.

	throws_ok {
		$user_rs->deleteCourseUser({ course_name => "Arithmetic", username => "marge" });
	}
	"DB::Exception::UserNotInCourse", "deleteUser: the user is not a member of the course";

## deleteUser: send in username_name instead of username

	throws_ok {
		$user_rs->deleteCourseUser({ course_name => "Arithmetic", username_name => "bart" });
	}
	"DB::Exception::ParametersNeeded", "deleteUser: the incorrect information is passed in.";

}

done_testing;
