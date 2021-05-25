# 
# This tests the basic database CRUD functions with courses. 
#
use warnings;
use strict;

use lib "../../lib";

use Text::CSV qw/csv/;
use Data::Dump qw/dd/;
use List::MoreUtils qw(uniq);

use Test::More; 

use DB::Schema; 


# load the database
my $db_file = "sample_db.sqlite";
my $schema = DB::Schema->connect("dbi:SQLite:$db_file");

my $courses = $schema->resultset("Course");

## get a list of courses from the CSV file

my $students = csv (in => "students.csv", headers => "lc");
my @known_courses = uniq map { $_->{course_name}} @$students; 
@known_courses = sort @known_courses;

## check the list of all courses
my @courses_from_db = sort($courses->getCourses); 
is_deeply(\@courses_from_db,\@known_courses,"course names");

## get a single course

my $course = $courses->getCourse("Calculus");
is($course->course_name,"Calculus","get a single course");

## add a course
my $new_course = $courses->addCourse("Geometry");
push(@known_courses,$new_course->course_name);
@known_courses = sort(@known_courses); 
@courses_from_db = sort($courses->getCourses);
is_deeply(\@courses_from_db,\@known_courses,"add a course");

## update a course 

my $updated_course = $courses->updateCourse("Geometry",{course_name => "Geometry II"});
@known_courses = sort map { $_ eq 'Geometry' ? 'Geometry II' : $_ } @known_courses;
@courses_from_db = sort($courses->getCourses);
is_deeply(\@courses_from_db,\@known_courses,"update a course");

## delete a course
my $deleted_course = $courses->deleteCourse("Geometry II");
@known_courses = grep { $_ ne $deleted_course->course_name} @known_courses;
@courses_from_db = sort($courses->getCourses); 
is_deeply(\@courses_from_db,\@known_courses,"deleted a course");



done_testing();

