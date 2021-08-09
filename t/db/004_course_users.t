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
use Try::Tiny;
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

my $course_rs = $schema->resultset("Course");
my $user_rs   = $schema->resultset("User");
my $cu_rs     = $schema->resultset("CourseUser");

## get a list of users from the CSV file
my @students = loadCSV("$main::test_dir/sample_data/students.csv");
for my $student (@students) {
	$student->{is_admin} = 0;
}

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
		removeIDs($user);
	}
}

is_deeply( \@precalc_students, \@precalc_students_from_db, "getUsers: get users from a course" );

## getUsers: test that an unknown course results in an error

throws_ok {
	$user_rs->getUsers( { course_name => "unknown_course" } );
}
'DB::Exception::CourseNotFound', "getUsers: undefined course_name";

throws_ok {
	$user_rs->getUsers( { course_id => -3 } );
}
'DB::Exception::CourseNotFound', "getUsers: undefined course_id";

## test getUser

my $user = $user_rs->getUser( { course_name => "Precalculus", login => $precalc_students[0]->{login} } );
removeIDs($user);
is_deeply( $precalc_students[0], $user, "getUser: get one user" );

## getUser: test that an unknown course results in an error

throws_ok {
	$user_rs->getUser( { course_name => "unknown_course", login => "barney" } );
}
'DB::Exception::CourseNotFound', "getUser: undefined course";

## getUser: test that an unknown user results in an error

throws_ok {
	$user_rs->getUser( { course_name => "Precalculus", login => "unknown_user" } );
}
'DB::Exception::UserNotInCourse', "getUser: undefined user";

## getUser: test that an existing user who is not in the course returns an error.

throws_ok {
	$user_rs->getUser( { course_name => "Arithmetic", login => "marge" } );
}
'DB::Exception::UserNotInCourse', "getUser: get a user that is not in the course";

## addUser:  add a user to a course

# remove the following user if already defined in the course
try {
	my $quimby = $user_rs->getUser( {course_name => "Arithmetic", login => "quimby"},1);
	$quimby->delete if defined $quimby;
};

my $user_params = {
	login      => "quimby",
	first_name => "Joe",
	last_name  => "Quimby",
	email      => 'mayor_joe@springfield.gov',
	student_id => "12345",
	role       => "student",
	params     => {},
	recitation => undef,
	section    => undef,
	is_admin   => 0,
};

$user = $user_rs->addUser( { course_name => "Arithmetic" }, $user_params );

removeIDs($user);
delete $user_params->{course_name};

is_deeply( $user_params, $user, "addUser: add a user to a course" );

## addUser: check that if the course doesn't exist, an error is thrown:

throws_ok {
	$user_rs->addUser( { course_name => "unknown_course", login => "barney" } );
}
"DB::Exception::CourseNotFound", "addUser: the course doesn't exist";

## addUser: the course exists, but the user is already a member.

throws_ok {
	$user_rs->addUser( { course_name => "Arithmetic" }, { login => "moe" } );
}
"DB::Exception::UserAlreadyInCourse", "addUser: the user is already a member";

## updateUser: check that the user updates.

my $updated_user = { params => { email => 'joe_the_mayor@juno.com', comment => 'Mayor Joe is the best!!' } };

for my $key ( keys %$updated_user ) {
	$user_params->{$key} = $updated_user->{$key};
}

my $user_from_db = $user_rs->updateUser( { course_name => 'Arithmetic', login => 'quimby' }, $updated_user );

removeIDs($user_from_db);

is_deeply( $user_params, $user_from_db, "updateUser: update a single user in an existing course." );

## updateUser: check that if the course doesn't exist, an error is thrown:
throws_ok {
	$user_rs->updateUser( { course_name => "unknown_course", login => "barney" }, $updated_user );
}
"DB::Exception::CourseNotFound", "updateUser: the course doesn't exist";

## updateUser: check that if the course exists, but the user not a member.
throws_ok {
	$user_rs->updateUser( { course_name => "Arithmetic", login => "marge" }, $updated_user );
}
"DB::Exception::UserNotInCourse", "updateUser: the user is not a member of the course";

## updateUser: send in wrong information

throws_ok {
	$user_rs->updateUser( { course_name => "Arithmetic", login_name => "bart" }, $updated_user );
}
"DB::Exception::ParametersNeeded", "updateUser: the incorrect information is passed in.";

## updateUser: update a user with nonvalid fields

throws_ok {
	$user_rs->updateUser( { course_name => "Arithmetic", login => "quimby" }, { sleeps_in_class => 1 } );
}
"DB::Exception::ParametersNeeded", "updateUser: an invalid field is set";



###
#   Check UserCourse methods
###

my $course_user2 = $user_rs->getCourseUser({ course_name => "Arithmetic", login=> "quimby" });
removeIDs($course_user2);

my $user_params2 = {};
for my $key (keys %$course_user2) {
	$user_params2->{$key} = $user_params->{$key};
}

is_deeply($user_params2,$course_user2,"getCourseUser: get a course user");

# check that a non-existent user throws an error:

throws_ok {
	$user_rs->getCourseUser({ course_name => "Arithmetic", login => "non_existent_user"})
}
"DB::Exception::UserNotFound", "getCourseUser: try to get a non-existent user";

# check that a non-existent course throws an error:

throws_ok {
	$user_rs->getCourseUser({ course_name => "non_existent_course", login => "bart"})
}
"DB::Exception::CourseNotFound", "getCourseUser: try to get a non-existent course";

# check that getting a user not enrolled throws an error

throws_ok {
	$user_rs->getCourseUser({ course_name => "Arithmetic", login => "marge"})
}
"DB::Exception::UserNotInCourse", "getCourseUser: try to get a user not enrolled";

# remove the following user if already defined in the course
my $apu = $user_rs->find({login=>"apu"});
my $arithmetic = $course_rs->find({course_name => "Arithmetic"});
my $apu_cu = $cu_rs->find({user_id => $apu->user_id, course_id => $arithmetic->course_id});
$apu_cu->delete if defined $apu_cu;

my $course_user = {
	login => "apu",
	course_name => "Arithmetic",
	role => "instructor",
	params => {},
	recitation => undef,
	section => undef
};

my $course_user_from_db = $user_rs->addCourseUser($course_user);
removeIDs($course_user_from_db);

for my $key (qw/login course_name/) {
	delete $course_user->{$key};
}

is_deeply($course_user,$course_user_from_db,"addCourseUser: successfully adding a course user");

# try to add a non-existent user from a course:

throws_ok {
	$user_rs->addCourseUser({ course_name => "Arithmetic", login => "non_existent_user"})
}
"DB::Exception::UserNotFound", "getCourseUser: try to add a non-existent user to a course";

# check that a non-existent course throws an error:

throws_ok {
	$user_rs->addCourseUser({ course_name => "non_existent_course", login => "bart"})
}
"DB::Exception::CourseNotFound", "getCourseUser: try to add a user to a non-existent course";

## TODO: check that adding non-valid parameters throw errors.


$course_user->{recitation} = "2";

my $course_user3 = $user_rs->updateCourseUser({
		login => "apu",
		course_name => "Arithmetic"
	},{recitation => "2"});

removeIDs($course_user3);
is_deeply($course_user3, $course_user, "updateCourseUser: update a field");


## delete a course user

my $course_user_to_delete = $user_rs->deleteCourseUser({
		login => "apu",
		course_name => "Arithmetic",
	});
removeIDs($course_user_to_delete);
is_deeply($course_user_to_delete,$course_user, "deleteCourseUser: delete a course user");

## deleteUser: delete a single user from a course

my $deleted_user;

my $dont_delete_users;    # switch to not delete added users.

SKIP: {

	skip "delete added users", 4 if $dont_delete_users;

	$deleted_user = $user_rs->deleteUser( { course_name => "Arithmetic", login => "quimby" } );
	removeIDs($deleted_user);

	is_deeply( $user_params, $deleted_user, 'deleteUser: delete a user from a course' );

## deleteUser: check that if the course doesn't exist, an error is thrown:

	throws_ok {
		$user_rs->deleteUser( { course_name => "unknown_course", login => "barney" } );
	}
	"DB::Exception::CourseNotFound", "deleteUser: the course doesn't exist";

## deleteUser: check that if the course exists, but the user not a member.

	throws_ok {
		$user_rs->deleteUser( { course_name => "Arithmetic", login => "marge" } );
	}
	"DB::Exception::UserNotInCourse", "deleteUser: the user is not a member of the course";

## deleteUser: send in login_name instead of login

	throws_ok {
		$user_rs->deleteUser( { course_name => "Arithmetic", login_name => "bart" } );
	}
	"DB::Exception::ParametersNeeded", "deleteUser: the incorrect information is passed in.";

### delete the global User that was created.

	$user_rs->deleteGlobalUser( { login => $user_params->{login} } );
}


done_testing;