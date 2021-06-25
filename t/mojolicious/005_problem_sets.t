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

$t->get_ok('/api/sets')
	->content_type_is('application/json;charset=UTF-8')
	->json_is('/10/set_name' => "Quiz #1");

$t->get_ok('/api/courses/2/sets')
	->content_type_is('application/json;charset=UTF-8')
	->json_is('/1/set_name'=>"HW #2")
	->json_is('/1/dates/open' => 21);

# Pull out the id from the response
my $set_id = $t->tx->res->json('/3/set_id');

$t->get_ok("/api/courses/2/sets/$set_id")
	->content_type_is('application/json;charset=UTF-8')
	->json_is('/set_name' => "HW #1")
	->json_is('/set_type' => 'HW')
	->json_is('/dates/open' => 1);

# new problem set

my $new_set = {
	set_name => 'HW #9',
	dates => {
		open => 100,
		due => 500,
		answer => 500
	},
};

$t->post_ok("/api/courses/2/sets" => json => $new_set)
	->content_type_is('application/json;charset=UTF-8')
	->json_is('/set_name' => 'HW #9')
	->json_is('/set_type' => 'HW')
	->json_is('/dates/answer' => 500);

my $new_set_id = $t->tx->res->json('/set_id');

$t->put_ok("/api/courses/2/sets/$new_set_id" => json => { set_name => 'HW #11'})
	->content_type_is('application/json;charset=UTF-8')
	->json_is('/set_name' => 'HW #11');

$t->delete_ok("/api/courses/2/sets/$new_set_id")
	->content_type_is('application/json;charset=UTF-8')
	->json_is('/set_name' => 'HW #11');

$t->get_ok("/api/courses/1/sets/6")
	->content_type_is('application/json;charset=UTF-8')
	->json_is('/exception' => 'DB::Exception::SetNotInCourse');

done_testing;