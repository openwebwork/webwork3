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

use lib "$main::lib_dir";

use DB::Schema;

# this tests the api with common courses routes

# load the database
my $db_file = "$main::test_dir/sample_db.sqlite";
my $schema  = DB::Schema->connect("dbi:SQLite:$db_file");

my $t = Test::Mojo->new('webwork3');

$t->get_ok('/api/users')->content_type_is('application/json;charset=UTF-8')->json_is( '/0/first_name' => "Homer" )
	->json_is( '/0/email' => 'homer@aol.com' );

$t->get_ok('/api/users/2')->content_type_is('application/json;charset=UTF-8')->json_is( '/login' => "lisa" )
	->json_is( '/email' => 'lisa@google.com' );

## add a new user

my $new_user = {
	email      => 'maggie@abc.com',
	first_name => "Maggie",
	last_name  => "Simpson",
	login      => "maggie",
	student_id => "1234123423"
};

$t->post_ok( '/api/users' => json => $new_user )->status_is(200)->json_is( '/login' => $new_user->{login} );

# Pull out the id from the response
$new_user->{user_id} = $t->tx->res->json('/user_id');
is_deeply( $new_user, $t->tx->res->json, "addUser: global user added." );

## update the user

$new_user->{email} = 'maggie@juno.com';
$t->put_ok( "/api/users/" . $new_user->{user_id} => json => $new_user );
is_deeply( $new_user, $t->tx->res->json, "updateUser: global user updated" );

## test for exceptions

# try to get a non-existent user
$t->get_ok("/api/users/99999")->content_type_is('application/json;charset=UTF-8')
	->json_is( '/exception' => 'DB::Exception::UserNotFound' );

# try to update a user not in a course

$t->put_ok( "/api/users/99999" => json => { email => 'fred@happy.com' } )
	->content_type_is('application/json;charset=UTF-8')->json_is( '/exception' => 'DB::Exception::UserNotFound' );

# try to add a user without a login

my $another_new_user = { login_name => "this is the wrong field" };

$t->post_ok( "/api/users" => json => $another_new_user )->content_type_is('application/json;charset=UTF-8')
	->json_is( '/exception' => 'DB::Exception::ParametersNeeded' );

# try to delete a user not in a course
$t->delete_ok("/api/users/99999")->content_type_is('application/json;charset=UTF-8')
	->json_is( '/exception' => 'DB::Exception::UserNotFound' );

# delete the added user

$t->delete_ok("/api/users/$new_user->{user_id}")->status_is(200)->json_is( '/login' => $new_user->{login} );

done_testing;
