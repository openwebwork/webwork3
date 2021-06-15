package DB::Schema::Result::PoolProblem;
use base qw/DBIx::Class::Core/;
use strict;
use warnings;

### this is the table that stores pool problems.

__PACKAGE__->table('pool_problem');

__PACKAGE__->add_columns(
	pool_problem_id => {
		data_type         => 'integer',
		size              => 16,
		is_nullable       => 0,
		is_auto_increment => 1,
	},
	problem_pool_id => {
		data_type   => 'integer',
		size        => 16,
		is_nullable => 0
	},
	library_id => {
		data_type   => 'integer',
		size        => 16,
		is_nullable => 0,
	}
);

__PACKAGE__->set_primary_key('pool_problem_id');
__PACKAGE__->add_unique_constraint( [qw/problem_pool_id library_id/] );

__PACKAGE__->belongs_to( problem_pool_id => 'DB::Schema::Result::ProblemPool' );

1;
