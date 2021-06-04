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
use Test::Exception;
use DB::Schema; 


# load the database
my $db_file = "sample_db.sqlite";
my $schema = DB::Schema->connect("dbi:SQLite:$db_file");
# $schema->storage->debug(1);  # print out the SQL commands.

my $courses = $schema->resultset("Course");

## get a list of courses from the CSV file

my $students = csv (in => "sample_data/students.csv", headers => "lc");
my @known_courses = uniq map { $_->{course_name}; } @$students; 
@known_courses = map { {course_name => $_};} (sort @known_courses);

## check the list of all courses
my @courses_from_db = $courses->getCourses;
my $courses_from_db = sortByCourseName(removeCourseID(\@courses_from_db)); 
is_deeply($courses_from_db,\@known_courses,"getCourses: course names");

## get a single course by name

my $course = $courses->getCourse({course_name => "Calculus"});
my $calc_id = $course->{course_id}; 
delete $course->{course_id};
is_deeply($course,{course_name=>"Calculus"},"getCourse: get a single course by name");

## get a single course by course_id

$course = $courses->getCourse({course_id => $calc_id});
delete $course->{course_id};
is_deeply($course,{course_name=>"Calculus"},"getCourse: get a single course by id");

## try to get a single course with sending proper info:
dies_ok {
  $courses->getCourse({course_id=> $calc_id,course_name=>"Calculus"});
} "getCourse: sends too much info";
dies_ok {
  $courses->getCourse({name =>"Calculus"});
} "getCourse: sends wrong info";


## add a course
my $new_course = $courses->addCourse("Geometry");
push(@known_courses,{course_name => $new_course->{course_name}});
my $known_courses = sortByCourseName(\@known_courses);

@courses_from_db = $courses->getCourses;
$courses_from_db = sortByCourseName(removeCourseID(\@courses_from_db)); 

is_deeply($known_courses,$courses_from_db,"addCourse: add a new course");

## add a course that already exists

dies_ok {
  my $another_new_course = $courses->addCourse("Geometry");
} "addCourse: course already exists";

## update a course 

my $new_course_params = {course_name => "Geometry II"};
my $updated_course = $courses->updateCourse(
  {course_name => "Geometry"},
  $new_course_params);
my $new_course_id = $updated_course->{course_id};
delete $updated_course->{course_id};

is_deeply($new_course_params,$updated_course,"updateCourse: update a course by name");



## Try to update an non-existent course
dies_ok {
  $courses->updateCourse({course_name => "undefined_course"},$new_course_params);
} "updateCourse: update a non-existent course_name";

dies_ok {
  $courses->updateCourse({course_id => -9},$new_course_params);
} "updateCourse: update a non-existent course_id";


## delete a course
my $deleted_course = $courses->deleteCourse({course_name => "Geometry II"});
@known_courses = grep { $_->{course_name} ne "Geometry"} @known_courses;
$known_courses = sortByCourseName(\@known_courses);

@courses_from_db = $courses->getCourses;
$courses_from_db = sortByCourseName(removeCourseID(\@courses_from_db)); 
is_deeply($courses_from_db,\@known_courses,"deleteCourse: delete a course");

## try to delete a non-existent course by name
dies_ok {
  $courses->deleteCourse({course_name => "undefined_name"})
} "deleteCourse: delete a non-existent course_name";

## try to delete a non-existent course by id
dies_ok {
  $courses->deleteCourse({course_id => -9})
} "deleteCourse: delete a non-existent course_id";

sub sortByCourseName {
  my $courses = shift; 
  my @new_array = sort {$a->{course_name} cmp $b->{course_name} } @$courses;
  return \@new_array; 
}

sub removeCourseID {
  my $courses = shift; 
  for my $course (@$courses){
    delete $course->{course_id};
  }
  return $courses; 
}


done_testing();

