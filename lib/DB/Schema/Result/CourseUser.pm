package DB::Schema::Result::CourseUser;
use base qw/DBIx::Class::Core/;
use strict;
use warnings; 

__PACKAGE__->table('course_user');

__PACKAGE__->add_columns(
									course_user_id =>
									{ 
										data_type => 'integer',
										size      => 16,
										is_nullable => 0,
										is_auto_increment => 1,
									},
								course_id =>
									{ 
										data_type => 'integer',
										size      => 16,
										is_nullable => 0,
									},
                user_id =>
									{ 
										data_type => 'integer',
										size      => 16,
										is_nullable => 0,
									}
								);

__PACKAGE__->set_primary_key('course_user_id');

__PACKAGE__->belongs_to( user_id => 'DB::Schema::Result::User');
__PACKAGE__->belongs_to( course_id => 'DB::Schema::Result::Course');

1;