package DB::Schema::Result::ProblemPool;
use base qw/DBIx::Class::Core/;
use strict;
use warnings;

__PACKAGE__->table('problem_pool');

__PACKAGE__->add_columns(
	problem_pool_id => {
		data_type         => 'integer',
		size              => 16,
		is_nullable       => 0,
		is_auto_increment => 1,
	},
	course_id => {
		data_type   => 'integer',
		size        => 16,
		is_nullable => 0,
	},
	pool_name => {
		data_type   => 'text',
		size        => 256,
		is_nullable => 0,
	}
);

__PACKAGE__->set_primary_key('problem_pool_id');
__PACKAGE__->add_unique_constraint( [qw/course_id pool_name/] );

__PACKAGE__->has_many( pool_problems => 'DB::Schema::Result::PoolProblem', 'problem_pool_id' );

__PACKAGE__->belongs_to( courses => 'DB::Schema::Result::Course', 'course_id' );

1;
