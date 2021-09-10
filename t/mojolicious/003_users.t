#!/usr/bin/env perl

use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

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
use DB::TestUtils qw/loadSchema/;
use Clone qw/clone/;

# Test the api with common "users" routes

my $schema = loadSchema();

# remove the maggie user if exists in the database
my $maggie = $schema->resultset("User")->find({username => "maggie"});
$maggie->delete if defined($maggie);

use YAML::XS qw/LoadFile/;
my $config = clone(LoadFile("$main::lib_dir/../conf/webwork3.yml"));

my $t;

if ($TEST_PERMISSIONS) {
	$config->{ignore_permissions} = 0;
	$t = Test::Mojo->new( WeBWorK3 => $config );

	# and username
	$t->post_ok( '/webwork3/api/username' => json => { email => 'admin@google.com', password => 'admin' } )
		->content_type_is('application/json;charset=UTF-8')->json_is( '/logged_in' => 1 )
		->json_is( '/user/user_id' => 1 )->json_is( '/user/is_admin' => 1 );
} else {
	$config->{ignore_permissions} = 1;
	$t = Test::Mojo->new( WeBWorK3 => $config );
}

my @all_users = $schema->resultset("User")->getAllGlobalUsers();

$t->get_ok('/webwork3/api/users')
	->status_is(200)
	->content_type_is('application/json;charset=UTF-8')
	->json_is( '/1/first_name' => $all_users[1]->{first_name} )
	->json_is( '/1/email' => $all_users[1]->{email} );


$t->get_ok('/webwork3/api/users/3')
	->status_is(200)
	->content_type_is('application/json;charset=UTF-8')->json_is( '/username' => "lisa" )
	->json_is( '/email' => 'lisa@google.com' );

## add a new user

my $new_user = {
	email      => 'maggie@abc.com',
	first_name => "Maggie",
	last_name  => "Simpson",
	username      => "maggie",
	student_id => "1234123423",
	is_admin   => 0
};

$t->post_ok( '/webwork3/api/users' => json => $new_user )->status_is(200)
	->content_type_is('application/json;charset=UTF-8')->json_is( '/username' => $new_user->{username} );

# Pull out the id from the response
$new_user->{user_id} = $t->tx->res->json('/user_id');
is_deeply( $new_user, $t->tx->res->json, "addUser: global user added." );

## update the user

$new_user->{email} = 'maggie@juno.com';
$t->put_ok( "/webwork3/api/users/" . $new_user->{user_id} => json => $new_user )
	->status_is(200);
is_deeply( $new_user, $t->tx->res->json, "updateUser: global user updated" );

## add the user to the course
my $added_user_to_course = {
	user_id => $new_user->{user_id},
	role => "student"
};

$t->post_ok( "/webwork3/api/courses/4/users" => json => $added_user_to_course)
	->status_is(200)
	->content_type_is('application/json;charset=UTF-8');
	# ->json_is( '/username' => 'maggie')
	# ->json_is( '/role' => 'student');

# warn Dumper $t->tx->res->json;

## test for exceptions

# try to get a non-existent user
$t->get_ok("/webwork3/api/users/99999")->content_type_is('application/json;charset=UTF-8')
	->status_is(250,"exception status")
	->status_is(250, 'internal exception')
	->json_is( '/exception' => 'DB::Exception::UserNotFound' );

# try to update a user not in a course

$t->put_ok( "/webwork3/api/users/99999" => json => { email => 'fred@happy.com' } )
	->status_is(250,"exception status")
	->content_type_is('application/json;charset=UTF-8')->json_is( '/exception' => 'DB::Exception::UserNotFound' );

# try to add a user without a username

my $another_new_user = { username_name => "this is the wrong field" };

$t->post_ok( "/webwork3/api/users" => json => $another_new_user )
	->content_type_is('application/json;charset=UTF-8')
	->status_is(250,"exception status")
	->json_is( '/exception' => 'DB::Exception::ParametersNeeded' );

# try to delete a user not in a course
$t->delete_ok("/webwork3/api/users/99999")->content_type_is('application/json;charset=UTF-8')
	->status_is(250,"exception status")
	->json_is( '/exception' => 'DB::Exception::UserNotFound' );

# add another user to a course that is not a global user

my $another_user = {
	username => "bob",
	first_name => "Sideshow",
	last_name => "Bob",
	student_id => "933723",
	email => 'bob@sideshow.net'
};

$t->post_ok("/webwork3/api/users" => json => $another_user )
	->status_is(200)
	->content_type_is('application/json;charset=UTF-8')
	->json_is('/username' => $another_user->{username});

my $another_user_id = $t->tx->res->json("/user_id");

$t->post_ok("/webwork3/api/courses/4/users" => json => {
		user_id => $another_user_id,
		role => "student"
	})
	->status_is(200)
	->content_type_is('application/json;charset=UTF-8');


my $another_new_user_id = $t->tx->res->json('/user_id');

# delete the added users

$t->delete_ok("/webwork3/api/users/$new_user->{user_id}")
	->status_is(200)
	->json_is( '/username' => $new_user->{username} );

$t->delete_ok("/webwork3/api/users/$another_new_user_id")
	->status_is(200)
	->json_is( '/username' => $another_user->{username} );

## test that a non-admin user cannot access all of the routes

if ($TEST_PERMISSIONS) {
	$t->post_ok( '/webwork3/api/username' => json => { email => 'lisa@google.com', password => 'lisa' } )
		->status_is(200)
		->content_type_is('application/json;charset=UTF-8')->json_is( '/logged_in' => 1 )
		->json_is( '/user/username' => "lisa" )->json_is( '/user/is_admin' => 0 );

	$t->get_ok('/webwork3/api/users')->content_type_is('application/json;charset=UTF-8')
		->status_is(200)
		->json_is( '/has_permission' => 0 );

	$t->get_ok('/webwork3/api/users/1')->content_type_is('application/json;charset=UTF-8')
		->status_is(200)
		->json_is( '/has_permission' => 0 );

	$t->post_ok( '/webwork3/api/users' => json => $new_user )->content_type_is('application/json;charset=UTF-8')
		->status_is(200)
		->json_is( '/has_permission' => 0 );

	$t->put_ok( '/webwork3/api/users/1' => json => { email => 'lisa@aol.com' } )
		->status_is(200)
		->content_type_is('application/json;charset=UTF-8')->json_is( '/has_permission' => 0 );

	$t->delete_ok('/webwork3/api/users/1')->content_type_is('application/json;charset=UTF-8')
		->status_is(200)
		->json_is( '/has_permission' => 0 );

}

done_testing;
