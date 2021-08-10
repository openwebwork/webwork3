#
# This tests the basic database CRUD functions with courses.
#
use warnings;
use strict;

BEGIN {
	use File::Basename qw/dirname/;
	use Cwd qw/abs_path/;
	$main::test_dir = abs_path( dirname(__FILE__) );
	$main::lib_dir  = dirname( dirname($main::test_dir) ) . '/lib';
}

use lib "$main::lib_dir";

use Text::CSV qw/csv/;
use Data::Dump qw/dd/;
use Test::More;
use Test::Exception;
use Try::Tiny;
use Carp;
use YAML::XS qw/LoadFile/;

use DB::WithParams;
use DB::WithDates;
use DB::Schema;
use DB::TestUtils qw/loadCSV removeIDs/;

# load some configuration for the database:

my $config = LoadFile("$main::lib_dir/../conf/webwork3.yml");

my $schema;
# load the database
if ($config->{database} eq 'sqlite') {
	$schema  = DB::Schema->connect($config->{sqlite_dsn});
} elsif ($config->{database} eq 'mariadb') {
	$schema  = DB::Schema->connect($config->{mariadb_dsn},$config->{database_user},$config->{database_password});
}

# $schema->storage->debug(1);  # print out the SQL commands.

my $users_rs = $schema->resultset("User");

# remove the maggie user if exists in the database
my $maggie = $users_rs->find({login => "maggie"});
$maggie->delete if defined($maggie);


## get a list of users from the CSV file
my @students = loadCSV("$main::test_dir/sample_data/students.csv");

# remove duplicates
my %seen = ();
@students = grep { !$seen{ $_->{login} }++ } @students;

# dd \@unique;

for my $student (@students) {
	for my $key (qw/course_name recitation section params role/) {
		delete $student->{$key};
	}
	$student->{is_admin} = 0;
}

# add the admin user
push(
	@students,
	{   login      => "admin",
		email      => 'admin@google.com',
		is_admin   => 1,
		first_name  => "Andrea",
		last_name => "Administrator",
		student_id => undef
	}
);
my @all_students = sort { $a->{login} cmp $b->{login} } @students;

## get a list of all users

my @users_from_db = $users_rs->getAllGlobalUsers;
for my $user (@users_from_db) {
	removeIDs($user);
}
@users_from_db = sort { $a->{login} cmp $b->{login} } @users_from_db;

is_deeply( \@all_students, \@users_from_db, "getUsers: all users" );

# dd \@all_students;
# dd \@users_from_db;

## get one user that exists

my $user = $users_rs->getGlobalUser( { login => $all_students[0]->{login} } );
removeIDs($user);
delete $user->{role};
is_deeply( $all_students[0], $user, "getUser: by login" );

$user = $users_rs->getGlobalUser( { user_id => 2 } );
removeIDs($user);
my @stud2 = grep { $_->{login} eq $user->{login} } @all_students;
is_deeply( $stud2[0], $user, "getUser: by user_id" );

## get one user that does not exist

throws_ok {
	$user = $users_rs->getGlobalUser( { user_id => -9 } );
}
"DB::Exception::UserNotFound", "getUser: undefined user_id";

throws_ok {
	$user = $users_rs->getGlobalUser( { login => "non_existent_user" } );
}
"DB::Exception::UserNotFound", "getUser: undefined login";

## add one user

$user = {
	login      => "wiggam",
	last_name  => "Wiggam",
	first_name => "Clancy",
	email      => 'wiggam@springfieldpd.gov',
	student_id => '',
	is_admin   => 0,
};

my $new_user = $users_rs->addGlobalUser($user);
removeIDs($new_user);
is_deeply( $user, $new_user, "addUser: adding a user" );

## update a user

my $updated_user = {%$user};    # make a copy of $user;
$updated_user->{email} = 'spring.cop@gmail.com';
my $up_user_from_db = $users_rs->updateGlobalUser( { login => $updated_user->{login} }, $updated_user );
removeIDs($up_user_from_db);
is_deeply( $updated_user, $up_user_from_db, "updateUser: updating a user" );

## try to update a user without passing login info:

throws_ok {
	$users_rs->updateGlobalUser( { login_name => "wiggam" }, $updated_user );
}
"DB::Exception::ParametersNeeded", "updateUser: wrong user_info sent";

## try to update a user that doesn't exist:

throws_ok {
	$users_rs->updateGlobalUser( { login => "non_existent_user" }, $updated_user );
}
"DB::Exception::UserNotFound", "updateUser: update user for a non-existing login";

throws_ok {
	$users_rs->updateGlobalUser( { user_id => -5 }, $updated_user );
}
"DB::Exception::UserNotFound", "updateUser: update user for a non-existing user_id";

## delete a user

my $user_to_delete = $users_rs->deleteGlobalUser( { login => $user->{login} } );

delete $user_to_delete->{user_id};
is_deeply( $updated_user, $user_to_delete, "deleteUser: delete a user" );

## delete a user that doesn't exist.

throws_ok {
	$user = $users_rs->deleteGlobalUser( { login => "undefined_login" } );
}
"DB::Exception::UserNotFound", "deleteUser: trying to delete with undefined login";

throws_ok {
	$user = $users_rs->deleteGlobalUser( { user_id => -3 } );
}
"DB::Exception::UserNotFound", "deleteUser: trying to delete with undefined user_id";

done_testing;

1;

