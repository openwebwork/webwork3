use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use Data::Dump qw/dd/;

BEGIN {
	use File::Basename qw/dirname/;
	use Cwd qw/abs_path/;
	$main::test_dir = abs_path( dirname(__FILE__) );
	$main::lib_dir  = dirname( dirname($main::test_dir) ) . '/lib';
}

use Getopt::Long;
my $TEST_PERMISSIONS;
GetOptions( "perm" => \$TEST_PERMISSIONS );    # check for the flag --perm when running this.

use lib "$main::lib_dir";

use DB::Schema;

# this tests the api with common courses routes

# load the database
my $db_file = "$main::test_dir/../db/sample_db.sqlite";
my $schema  = DB::Schema->connect("dbi:SQLite:$db_file");

my $t;

if ($TEST_PERMISSIONS) {
	$t = Test::Mojo->new( WeBWorK3 => { ignore_permissions => 0, secrets => [1234] } );

	# login an admin
	$t->post_ok( '/webwork3/api/login' => json => { email => 'admin@google.com', password => 'admin' } )
		->status_is(200)->content_type_is('application/json;charset=UTF-8')->json_is( '/logged_in' => 1 )
		->json_is( '/user/user_id' => 1 )->json_is( '/user/is_admin' => 1 );

}
else {
	$t = Test::Mojo->new( WeBWorK3 => { ignore_permissions => 1, secrets => [1234] } );
}

$t->get_ok('/webwork3/api/sets')->content_type_is('application/json;charset=UTF-8')
	->json_is( '/10/set_name' => "Quiz #1" );

$t->get_ok('/webwork3/api/courses/2/sets')->content_type_is('application/json;charset=UTF-8')
	->json_is( '/1/set_name' => "HW #2" )->json_is( '/1/dates/open' => 21 );

# Pull out the id from the response
my $set_id = $t->tx->res->json('/3/set_id');

$t->get_ok("/webwork3/api/courses/2/sets/$set_id")->content_type_is('application/json;charset=UTF-8')
	->json_is( '/set_name' => "HW #1" )->json_is( '/set_type' => 'HW' )->json_is( '/dates/open' => 1 );

# new problem set

my $new_set = {
	set_name => 'HW #9',
	dates    => {
		open   => 100,
		due    => 500,
		answer => 500
	},
};

$t->post_ok( "/webwork3/api/courses/2/sets" => json => $new_set )->content_type_is('application/json;charset=UTF-8')
	->json_is( '/set_name' => 'HW #9' )->json_is( '/set_type' => 'HW' )->json_is( '/dates/answer' => 500 );

my $new_set_id = $t->tx->res->json('/set_id');

$t->put_ok( "/webwork3/api/courses/2/sets/$new_set_id" => json => { set_name => 'HW #11' } )
	->content_type_is('application/json;charset=UTF-8')->json_is( '/set_name' => 'HW #11' );

## test for exceptions

# a set that is not in a course
$t->get_ok("/webwork3/api/courses/1/sets/6")->content_type_is('application/json;charset=UTF-8')
	->json_is( '/exception' => 'DB::Exception::SetNotInCourse' );

# try to update a set not in a course

$t->put_ok( "/webwork3/api/courses/1/sets/6" => json => { set_name => 'HW #99' } )
	->content_type_is('application/json;charset=UTF-8')->json_is( '/exception' => 'DB::Exception::SetNotInCourse' );

# try to add a set without a setname

my $another_new_set = { name => "this is the wrong field" };

$t->post_ok( "/webwork3/api/courses/2/sets" => json => $another_new_set )
	->content_type_is('application/json;charset=UTF-8')->json_is( '/exception' => 'DB::Exception::ParametersNeeded' );

# delete an existing set

$t->delete_ok("/webwork3/api/courses/2/sets/$new_set_id")->content_type_is('application/json;charset=UTF-8')
	->json_is( '/set_name' => 'HW #11' );

# try to delete a set not in a course
$t->delete_ok("/webwork3/api/courses/1/sets/6")->content_type_is('application/json;charset=UTF-8')
	->json_is( '/exception' => 'DB::Exception::SetNotInCourse' );

if ($TEST_PERMISSIONS) {
	$t->post_ok("/webwork3/api/logout")->status_is(200)->json_is( '/logged_in' => 0 );
}

## check that a non_admin user has proper access.

my @all_users   = $schema->resultset("User")->getUsers( { course_id => 1 } );
my @instructors = grep { $_->{role} eq 'instructor' } @all_users;

if ($TEST_PERMISSIONS) {
	$t->post_ok(
		"/webwork3/api/login" => json => { email => $instructors[0]->{email}, password => $instructors[0]->{login} } )
		->status_is(200)->content_type_is('application/json;charset=UTF-8')->json_is( '/logged_in' => 1 );

	$t->get_ok('/webwork3/api/courses/1/sets')->status_is(200)->content_type_is('application/json;charset=UTF-8');

	# ->json_is('/0' => $all_users[0]->{first_name});

	# dd $t->tx->res->json;
}

done_testing;
