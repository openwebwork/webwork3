package DB::Schema::Result::ProblemSet;
use base qw/DBIx::Class::Core/;
use strict;
use warnings; 


__PACKAGE__->table('problem_set');

__PACKAGE__->add_columns(
								set_id =>
									{ 
										data_type => 'integer',
										size      => 16,
										is_nullable => 0,
										is_auto_increment => 1,
									},
								set_name =>
									{ 
										data_type => 'text',
										size      => 256,
										is_nullable => 0,
									},
								course_id  =>
									{ 
										data_type => 'integer',
                    size => 16,   
										is_nullable => 1,
									},
								open_date  =>
									{ 
										data_type => 'integer',
										size => 16,   
										is_nullable => 0,
									},
								reduced_scoring_date  =>
									{ 
										data_type => 'integer',
                    size => 16,   
										is_nullable => 0,
									},
								due_date  =>
									{ 
										data_type => 'integer',
                    size => 16,   
										is_nullable => 0,
									},
								answer_date  =>
									{ 
										data_type => 'integer',
										size => 16,   
										is_nullable => 0,
									},
								);

__PACKAGE__->set_primary_key('set_id');
__PACKAGE__->belongs_to(courses => 'DB::Schema::Result::Course','course_id');
__PACKAGE__->has_many(problems => 'DB::Schema::Result::Problem','set_id');
__PACKAGE__->has_many(user_sets => 'DB::Schema::Result::UserSet','set_id');

1;