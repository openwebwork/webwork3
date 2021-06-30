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
GetOptions ("perm"  => \$TEST_PERMISSIONS);  # check for the flag --perm when running this.


use lib "$main::lib_dir";

use DB::Schema;

# this tests the api with common courses routes

# load the database
my $db_file = "$main::test_dir/../../t/db/sample_db.sqlite";
my $schema  = DB::Schema->connect("dbi:SQLite:$db_file");

my $t;

if ($TEST_PERMISSIONS) {
	$t = Test::Mojo->new( webwork3 => { ignore_permissions => 0, secrets => [1234] } );

	# login an admin
	$t->post_ok( '/api/login' => json => { email => 'admin@google.com', password => 'admin' } )
		->status_is(200)
		->content_type_is('application/json;charset=UTF-8')
		->json_is( '/logged_in' => 1 )
		->json_is( '/user/user_id' => 1 )
		->json_is( '/user/is_admin' => 1 );

} else {
	$t = Test::Mojo->new( webwork3 => { ignore_permissions => 1, secrets => [1234] });
}

$t->get_ok('/api/courses/2/users')
	->status_is(200)
	->content_type_is('application/json;charset=UTF-8')
	->json_is( '/1/first_name' => "Apu" )->json_is( '/0/email' => 'lisa@google.com' );


# Pull out the id from the response
my $user_id = $t->tx->res->json('/0/user_id');

$t->get_ok("/api/courses/2/users/$user_id")
	->status_is(200)
	->content_type_is('application/json;charset=UTF-8')
	->json_is( '/first_name' => "Lisa" );


## add a new user to a course

my $new_user = {
	email      => 'maggie@abc.com',
	first_name => "Maggie",
	last_name  => "Simpson",
	login      => "maggie",
	student_id => "1234123423"
};

$t->post_ok( "/api/courses/2/users" => json => $new_user )->content_type_is('application/json;charset=UTF-8')
	->json_is( '/first_name' => 'Maggie' );

# update the new user
my $new_user_id = $t->tx->res->json('/user_id');
$new_user->{recitation} = 2;
$t->put_ok( "/api/courses/2/users/$new_user_id" => json => { recitation => 2 } )
	->status_is(200)
	->content_type_is('application/json;charset=UTF-8')
	->json_is( '/recitation' => 2 );

## test for exceptions

# a user that is not in a course
$t->get_ok("/api/courses/1/users/99")
	->status_is(200)
	->content_type_is('application/json;charset=UTF-8')
	->json_is( '/exception' => 'DB::Exception::UserNotInCourse' );

# try to update a user not in a course

$t->put_ok( "/api/courses/1/users/99" => json => { recitation => '2' } )
	->status_is(200)
	->content_type_is('application/json;charset=UTF-8')
	->json_is( '/exception' => 'DB::Exception::UserNotInCourse' );

# try to add a user without a login

my $another_new_user = { login_name => "this is the wrong field" };

$t->post_ok( "/api/courses/1/users" => json => $another_new_user )
	->status_is(200)
	->content_type_is('application/json;charset=UTF-8')
	->json_is( '/exception' => 'DB::Exception::ParametersNeeded' );

# try to delete a user not in a course
$t->delete_ok("/api/courses/1/users/99")
	->status_is(200)
	->content_type_is('application/json;charset=UTF-8')
	->json_is( '/exception' => 'DB::Exception::UserNotInCourse' );

$t->delete_ok("/api/courses/2/users/$new_user_id")
	->status_is(200)
	->content_type_is('application/json;charset=UTF-8')
	->json_is( '/login' => 'maggie' );


if ($TEST_PERMISSIONS) {
	$t->post_ok("/api/logout")
		->status_is(200)
		->json_is('/logged_in' => 0);
}

## check that a non_admin user has proper access.

my @all_users = $schema->resultset("User")->getUsers({course_id => 1});
my @instructors = grep {$_->{role} eq 'instructor'} @all_users;

if ($TEST_PERMISSIONS) {
	$t->post_ok("/api/login" => json => { email => $instructors[0]->{email}, password => $instructors[0]->{login}})
		->status_is(200)
		->content_type_is('application/json;charset=UTF-8')
		->json_is('/logged_in' => 1);

	$t->get_ok('/api/courses/1/users')
		->status_is(200)
		->content_type_is('application/json;charset=UTF-8');
		# ->json_is('/0' => $all_users[0]->{first_name});

	# dd $t->tx->res->json;
}

done_testing;