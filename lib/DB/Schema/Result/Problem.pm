package DB::Schema::Result::Problem;
use DBIx::Class::Core;
use DB::WithParams;

our @ISA = qw(DBIx::Class::Core DB::WithParams);
use strict;
use warnings;

use JSON; 

our $VALID_PARAMS = {
	weight => '\d+',
	library_id => '\d+',
	problem_path => '.*',
	problem_pool_id => '\d+'
}; 

our $REQUIRED_PARAMS = 
	{
		'_ALL_' => [
				'weight',
				{'_ONE_OF_' => ['library_id','problem_path','problem_pool_id']} 
			]
	};


### this is the table that stores problems for a given Problem Set

__PACKAGE__->table('problem');

__PACKAGE__->add_columns(
								problem_id =>
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
								problem_number => 
									{
										data_type => 'integer',
										size => 16,
										is_nullable => 1,
									},
								problem_version => 
									{
										data_type => 'integer',
										size => 8,
										is_nullable => 0,
										default_value => 1
									},
								params => # store params as a JSON object
									{
										data_type => 'text',
										size => 256,
										is_nullable => 0,
										default_value => '{}'
									}
								);

__PACKAGE__->set_primary_key('problem_id');
__PACKAGE__->add_unique_constraint([ qw/problem_id set_id problem_version problem_number/ ]); # maybe we don't need this. 


__PACKAGE__->belongs_to(problem_set => 'DB::Schema::Result::ProblemSet','set_id');

__PACKAGE__->has_many(user_problem => 'DB::Schema::Result::UserProblem','problem_id');

### Handle the params column using JSON. 

__PACKAGE__->inflate_column('params', {
	inflate => sub {
		decode_json shift;
	},
	deflate => sub {
		encode_json shift; 
	}
});

1;