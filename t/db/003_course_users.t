#
# This tests the basic database CRUD functions of course users.
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
use List::Util qw(uniq);
use Test::More;
use Test::Exception;

use DB::WithParams;
use DB::WithDates; 
use DB::Schema;
use DB::TestUtils qw/loadCSV/;

# load the database
my $db_file = "$main::test_dir/sample_db.sqlite";
my $schema  = DB::Schema->connect("dbi:SQLite:$db_file");

# $schema->storage->debug(1);  # print out the SQL commands.

my $course_rs = $schema->resultset("Course");
my $user_rs   = $schema->resultset("User");

## get a list of users from the CSV file
my @students = loadCSV("$main::test_dir/sample_data/students.csv");

## filter only precalc students
my @precalc_students = grep { $_->{course_name} eq "Precalculus" } @students;
for my $student (@precalc_students) {
	delete $student->{course_name};
}
@precalc_students = sort { $a->{login} cmp $b->{login} } @precalc_students;

## test getUsers

my @users                    = $user_rs->getUsers( { course_name => "Precalculus" } );
my @precalc_students_from_db = sort { $a->{login} cmp $b->{login} } @users;
my $precalc_students_from_db = removeCourseUserIDs( \@precalc_students_from_db );

sub removeCourseUserIDs {
	my $users = shift;
	for my $user (@$users) {
		for my $key (qw/course_id user_id course_user_id/) {
			delete $user->{$key};
		}
	}
}

is_deeply( \@precalc_students, \@precalc_students_from_db, "getUsers: get users from a course" );

## getUsers: test that an unknown course results in an error

dies_ok {
	my @users = $course_rs->getUsers( { course_name => "unknown_course" } );
}
"getUsers: undefined course_name";
dies_ok {
	my @users = $course_rs->getUsers( { course_id => -3 } );
}
"getUsers: undefined course_id";

## test getUser

my $user = $user_rs->getUser( { course_name => "Precalculus", login => $precalc_students[0]->{login} } );
for my $key (qw/course_id user_id course_user_id/) {
	delete $user->{$key};
}

is_deeply( $precalc_students[0], $user, "getUser: get one user" );

## getUser: test that an unknown course results in an error

dies_ok {
	my @users = $course_rs->getUsers( { course_name => "unknown_course", login => "barney" } );
}
"getUser: undefined course";

## getUser: test that an unknown user results in an error

dies_ok {
	my @users = $course_rs->getUsers( { course_name => "Precalculus", login => "unknown_user" } );
}
"getUser: undefined user";

## addUser:  add a user to a course

my $user_params = {
	course_name => "Arithmetic",
	login       => "quimby",
	first_name  => "Joe",
	last_name   => "Quimby",
	email       => 'mayor_joe@springfield.gov',
	student_id  => "12345",
	role       => "student",
	params      => {},
	recitation  => undef,
	section     => undef,
};

$user = $user_rs->addUser( { course_name => "Arithmetic" }, $user_params );

for my $key (qw/course_id user_id course_user_id/) {
	delete $user->{$key};
}
delete $user_params->{course_name};

is_deeply( $user_params, $user, "addUser: add a user succeeds" );

## addUser: check that if the course doesn't exist, an error is thrown:
dies_ok {
	my $user = $course_rs->addUser( { course_name => "unknown_course", login => "barney" } );
}
"addUser: the course doesn't exist";

## addUser: check that if the course exists, but the user is already a member.
dies_ok {
	my $user = $course_rs->addUser( { course_name => "Arithmetic", login => "moe" } );
}
"addUser: the user is already a member";

## updateUser: check that the user updates.

my $updated_user = {%$user_params};    # make a copy of $user;
$updated_user->{params}->{email}   = 'joe_the_mayor@juno.com';
$updated_user->{params}->{comment} = 'Mayor Joe is the best!!';
my $user_from_db = $user_rs->updateUser( { course_name => 'Arithmetic', login => 'quimby' }, $updated_user );

for my $key (qw/course_id user_id course_user_id/) {
	delete $user_from_db->{$key};
}

is_deeply( $updated_user, $user_from_db, "updateUser: update a single user in an existing course." );

## updateUser: check that if the course doesn't exist, an error is thrown:
dies_ok {
	my $user = $course_rs->updateUser( { course_name => "unknown_course", login => "barney" } );
}
"updateUser: the course doesn't exist";

## updateUser: check that if the course exists, but the user is already a member.
dies_ok {
	my $user = $course_rs->updateUser( { course_name => "Arithmetic", login => "bart" } );
}
"updateuser: the user is not a member of the course";

## deleteUser: delete a single user from a course

my $deleted_user = $user_rs->deleteUser( { course_name => "Arithmetic", login => "quimby" } );
for my $key (qw/course_id user_id course_user_id/) {
	delete $deleted_user->{$key};
}

is_deeply( $updated_user, $deleted_user, 'deleteUser: delete a user from a course' );

## deleteUser: check that if the course doesn't exist, an error is thrown:
dies_ok {
	my $user = $course_rs->deleteUser( { course_name => "unknown_course", login => "barney" } );
}
"deleteUser: the course doesn't exist";

## deleteUser: check that if the course exists, but the user is already a member.
dies_ok {
	my $user = $course_rs->deleteUser( { course_name => "Arithmetic", login => "bart" } );
}
"deleteUser: the user is not a member of the course";

### delete the global User that was created. 

$user_rs->deleteGlobalUser({login => $user_params->{login}});

done_testing;

1;
