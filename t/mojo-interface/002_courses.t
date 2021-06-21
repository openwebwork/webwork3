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

$t->get_ok('/api/courses')
	->content_type_is('application/json;charset=UTF-8')
	->json_is('/0/course_name'=>"Precalculus")
	->json_is('/0/course_params/institution' => "Springfield CC");

$t->get_ok('/api/courses/1')
	->content_type_is('application/json;charset=UTF-8')
	->json_is('/course_name'=>"Precalculus")
	->json_is('/course_params/institution' => "Springfield CC");

## add a new course

my $new_course = {
	course_name => "Linear Algebra",
	course_params => {institution => "Springfield A&M"},
	course_dates => {start => "2021-05-31", end => "2021-07-01"}
}; 

$t->post_ok('/api/courses' => json => $new_course)
	->status_is(200)
	->json_is('/course_name' => $new_course->{course_name});

# Pull out the id from the response
my $new_course_id = $t->tx->res->json('/course_id');
$new_course->{course_id} = $new_course_id; 
is_deeply($new_course,$t->tx->res->json,"addCourse: courses match"); 


## update the course

$new_course->{course_params}->{institution} = "Springfield University"; 
$t->put_ok("/api/courses/$new_course_id" => json => $new_course);
is_deeply($new_course,$t->tx->res->json,"updateCourse: courses match");


# delete the added course

$t->delete_ok("/api/courses/$new_course_id")
	->status_is(200)
	->json_is('/course_name' => $new_course->{course_name});

done_testing;