package DB::Schema::Result::UserSet;
use base qw/DBIx::Class::Core/;
use strict;
use warnings; 


__PACKAGE__->table('user_set');

__PACKAGE__->add_columns(
								user_set_id =>
									{ 
										data_type => 'integer',
										size      => 16,
										is_nullable => 0,
										is_auto_increment => 1,
									},
								set_id =>
									{ 
										data_type => 'integer',
										size      => 16,
										is_nullable => 0,
									},
								user_id  =>
									{ 
										data_type => 'integer',
                    size => 16,   
										is_nullable => 0,
									},
								open_date  =>
									{ 
										data_type => 'integer',
										size => 16,   
										is_nullable => 1,
									},
								reduced_scoring_date  =>
									{ 
										data_type => 'integer',
                    size => 16,   
										is_nullable => 1,
									},
								due_date  =>
									{ 
										data_type => 'integer',
                    size => 16,   
										is_nullable => 1,
									},
								answer_date  =>
									{ 
										data_type => 'integer',
										size => 16,   
										is_nullable => 1,
									},
								);

__PACKAGE__->set_primary_key('user_set_id');
__PACKAGE__->belongs_to(course_users => 'DB::Schema::Result::CourseUser','user_id');
__PACKAGE__->belongs_to(problem_sets => 'DB::Schema::Result::ProblemSet','set_id');

1;