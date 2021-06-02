package DB::Schema::Result::ProblemPool;
use base qw/DBIx::Class::Core/;
use strict;
use warnings; 

__PACKAGE__->table('problem_pool');

__PACKAGE__->add_columns(
									problem_pool_id =>
									{ 
										data_type => 'integer',
										size      => 16,
										is_nullable => 0,
										is_auto_increment => 1,
									},
								name =>
									{ 
										data_type => 'text',
										size      => 256,
										is_nullable => 0,
									},
								problems =>  # store problems as JSON array
									{
										data_type => 'text',
										size=> 256,
										is_nullable => 0,
										default_value => '[]'
									}
								);

__PACKAGE__->set_primary_key('problem_pool_id');


1;
