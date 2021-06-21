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

$t->get_ok('/api/courses/2/users')
	->content_type_is('application/json;charset=UTF-8')
	->json_is('/1/first_name'=>"Apu")
	->json_is('/0/email' => 'lisa@google.com');

	# Pull out the id from the response
my $user_id = $t->tx->res->json('/0/user_id');


$t->get_ok("/api/courses/2/users/$user_id")
	->content_type_is('application/json;charset=UTF-8')
	->json_is('/first_name'=>"Lisa");

## add a new user to a course

my $new_user = {
	email => 'maggie@abc.com',
	first_name => "Maggie",
	last_name => "Simpson",
	login => "maggie",
	student_id => "1234123423"
}; 

$t->post_ok("/api/courses/2/users" => json => $new_user)
	->content_type_is('application/json;charset=UTF-8')
	->json_is('/first_name' => 'Maggie');

# update the new user
my $new_user_id = $t->tx->res->json('/user_id');
$new_user->{recitation} = 2; 
$t->put_ok("/api/courses/2/users/$new_user_id" => json => {recitation => 2})
	->content_type_is('application/json;charset=UTF-8')
	->json_is('/recitation' => 2);

$t->delete_ok("/api/courses/2/users/$new_user_id")
	->content_type_is('application/json;charset=UTF-8')
	->json_is('/login' => 'maggie');

done_testing;