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

use DB::Schema;
use DB::TestUtils qw/loadCSV removeIDs/;
use YAML qw/LoadFile/;

# Load the database
my $config_file = "$main::ww3_dir/conf/ww3-dev.yml";
$config_file = "$main::ww3_dir/conf/ww3-dev.dist.yml" unless (-e $config_file);
my $config = LoadFile($config_file);
my $schema = DB::Schema->connect($config->{database_dsn}, $config->{database_user}, $config->{database_password});

my $users_rs = $schema->resultset("User");

# Remove the user "maggie" if it exists in the database
my $maggie = $users_rs->find({ username => "maggie" });
$maggie->delete if defined($maggie);

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

# Get a list of all users
my @users_from_db = $users_rs->getAllGlobalUsers;
for my $user (@users_from_db) {
	removeIDs($user);
}
@users_from_db = sort { $a->{username} cmp $b->{username} } @users_from_db;
is_deeply(\@all_students, \@users_from_db, "getUsers: all users");

# Get one user that exists
my $user = $users_rs->getGlobalUser({ username => $all_students[0]->{username} });
removeIDs($user);
delete $user->{role};
is_deeply($all_students[0], $user, "getUser: by username");

$user = $users_rs->getGlobalUser({ user_id => 2 });
removeIDs($user);
my @stud2 = grep { $_->{username} eq $user->{username} } @all_students;
is_deeply($stud2[0], $user, "getUser: by user_id");

# Get one user that does not exist
throws_ok {
	$user = $users_rs->getGlobalUser({ user_id => -9 });
}
"DB::Exception::UserNotFound", "getUser: undefined user_id";

throws_ok {
	$user = $users_rs->getGlobalUser({ username => "non_existent_user" });
}
"DB::Exception::UserNotFound", "getUser: undefined username";

# Add one user
$user = {
	username   => "wiggam",
	last_name  => "Wiggam",
	first_name => "Clancy",
	email      => 'wiggam@springfieldpd.gov',
	student_id => '',
	is_admin   => 0,
};
my $new_user = $users_rs->addGlobalUser($user);
removeIDs($new_user);
is_deeply($user, $new_user, "addUser: adding a user");

# Update a user
my $updated_user = {%$user};    # Make a copy of $user
$updated_user->{email} = 'spring.cop@gmail.com';
my $up_user_from_db = $users_rs->updateGlobalUser({ username => $updated_user->{username} }, $updated_user);
removeIDs($up_user_from_db);
is_deeply($updated_user, $up_user_from_db, "updateUser: updating a user");

# Try to update a user without passing username info
throws_ok {
	$users_rs->updateGlobalUser({ username_name => "wiggam" }, $updated_user);
}
"DB::Exception::ParametersNeeded", "updateUser: wrong user_info sent";

# Try to update a user that doesn't exist
throws_ok {
	$users_rs->updateGlobalUser({ username => "non_existent_user" }, $updated_user);
}
"DB::Exception::UserNotFound", "updateUser: update user for a non-existing username";

throws_ok {
	$users_rs->updateGlobalUser({ user_id => -5 }, $updated_user);
}
"DB::Exception::UserNotFound", "updateUser: update user for a non-existing user_id";

# Delete a user
my $user_to_delete = $users_rs->deleteGlobalUser({ username => $user->{username} });

delete $user_to_delete->{user_id};
is_deeply($updated_user, $user_to_delete, "deleteUser: delete a user");

# Delete a user that doesn't exist.
throws_ok {
	$user = $users_rs->deleteGlobalUser({ username => "undefined_username" });
}
"DB::Exception::UserNotFound", "deleteUser: trying to delete with undefined username";

throws_ok {
	$user = $users_rs->deleteGlobalUser({ user_id => -3 });
}
"DB::Exception::UserNotFound", "deleteUser: trying to delete with undefined user_id";

done_testing;

1;

