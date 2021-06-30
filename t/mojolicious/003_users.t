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

	# and login
	$t->post_ok( '/api/login' => json => { email => 'admin@google.com', password => 'admin' } )
		->content_type_is('application/json;charset=UTF-8')
		->json_is( '/logged_in' => 1 )
		->json_is( '/user/user_id' => 1 )
		->json_is( '/user/is_admin' => 1 );

} else {
	$t = Test::Mojo->new( webwork3 => { ignore_permissions => 1, secrets => [1234] });
}

my @all_users = $schema->resultset("User")->getAllGlobalUsers();

$t->get_ok('/api/users')
	->content_type_is('application/json;charset=UTF-8')
	->json_is( '/1/first_name' => $all_users[1]->{first_name} )
	->json_is( '/1/email' => $all_users[1]->{email} );

$t->get_ok('/api/users/3')
	->content_type_is('application/json;charset=UTF-8')
	->json_is( '/login' => "lisa" )
	->json_is( '/email' => 'lisa@google.com' );



## add a new user

my $new_user = {
	email      => 'maggie@abc.com',
	first_name => "Maggie",
	last_name  => "Simpson",
	login      => "maggie",
	student_id => "1234123423",
	is_admin => 0
};

$t->post_ok( '/api/users' => json => $new_user )
	->status_is(200)
	->content_type_is('application/json;charset=UTF-8')
	->json_is( '/login' => $new_user->{login} );

dd $t->tx->res->json;

# Pull out the id from the response
$new_user->{user_id} = $t->tx->res->json('/user_id');
is_deeply( $new_user, $t->tx->res->json, "addUser: global user added." );

## update the user

$new_user->{email} = 'maggie@juno.com';
$t->put_ok( "/api/users/" . $new_user->{user_id} => json => $new_user );
is_deeply( $new_user, $t->tx->res->json, "updateUser: global user updated" );

## test for exceptions

# try to get a non-existent user
$t->get_ok("/api/users/99999")
	->content_type_is('application/json;charset=UTF-8')
	->json_is( '/exception' => 'DB::Exception::UserNotFound' );

# try to update a user not in a course

$t->put_ok( "/api/users/99999" => json => { email => 'fred@happy.com' } )
	->content_type_is('application/json;charset=UTF-8')->json_is( '/exception' => 'DB::Exception::UserNotFound' );

# try to add a user without a login

my $another_new_user = { login_name => "this is the wrong field" };

$t->post_ok( "/api/users" => json => $another_new_user )
	->content_type_is('application/json;charset=UTF-8')
	->json_is( '/exception' => 'DB::Exception::ParametersNeeded' );

# try to delete a user not in a course
$t->delete_ok("/api/users/99999")
	->content_type_is('application/json;charset=UTF-8')
	->json_is( '/exception' => 'DB::Exception::UserNotFound' );

# delete the added user

$t->delete_ok("/api/users/$new_user->{user_id}")
	->status_is(200)
	->json_is( '/login' => $new_user->{login} );

## test that a non-admin user cannot access all of the routes

if ($TEST_PERMISSIONS) {
	$t->post_ok( '/api/login' => json => { email => 'lisa@google.com', password => 'lisa' } )
		->content_type_is('application/json;charset=UTF-8')
		->json_is( '/logged_in' => 1 )
		->json_is( '/user/login' => "lisa" )
		->json_is( '/user/is_admin' => 0 );

	$t->get_ok('/api/users')
		->content_type_is('application/json;charset=UTF-8')
		->json_is( '/has_permission' => 0);

	$t->get_ok('/api/users/1')
		->content_type_is('application/json;charset=UTF-8')
		->json_is( '/has_permission' => 0);

	$t->post_ok('/api/users' => json => $new_user)
		->content_type_is('application/json;charset=UTF-8')
		->json_is( '/has_permission' => 0);

	$t->put_ok('/api/users/1' => json => {email => 'lisa@aol.com'})
		->content_type_is('application/json;charset=UTF-8')
		->json_is( '/has_permission' => 0);

	$t->delete_ok('/api/users/1')
		->content_type_is('application/json;charset=UTF-8')
		->json_is( '/has_permission' => 0);

}

done_testing;
