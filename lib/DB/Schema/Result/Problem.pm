package DB::Schema::Result::Problem;
use base qw/DBIx::Class::Core/;
use strict;
use warnings; 

use JSON; 


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
								params => # store params as a JSON object
									{
										data_type => 'text',
										size => 256,
										is_nullable => 0,
										default_value => '{}'
									}
								);

__PACKAGE__->set_primary_key('problem_id');
__PACKAGE__->add_unique_constraint([ qw/problem_id set_id problem_number/ ]); # maybe we don't need this. 


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