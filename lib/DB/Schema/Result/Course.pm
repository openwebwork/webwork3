package DB::Schema::Result::Course;
use base qw/DBIx::Class::Core/;
use strict;
use warnings; 

__PACKAGE__->table('course');

__PACKAGE__->add_columns(
									course_id =>
									{ 
										data_type => 'integer',
										size      => 16,
										is_nullable => 0,
										is_auto_increment => 1,
									},
								course_name =>
									{ 
										data_type => 'text',
										size      => 256,
										is_nullable => 0,
									}
								);

__PACKAGE__->set_primary_key('course_id');

# set up the many-to-many relationship to users
__PACKAGE__->has_many( course_users => 'DB::Schema::Result::CourseUser','course_id');
__PACKAGE__->many_to_many( users => 'course_users', 'user_id' );

# set up the one-to-many relationship to problem_sets
__PACKAGE__->has_many( problem_sets => 'DB::Schema::Result::ProblemSet','course_id');


1;