package DB::Schema::Result::ProblemPool;
use base qw/DBIx::Class::Core/;
use strict;
use warnings;

=head1 DESCRIPTION

This is the database schema for a Problem Pool, which consists of a set of problems
that can be used in any type of Problem Set, typically to be drawn from
on a random basis.

=head2 fields

=over

=item *

C<problem_pool_id>: database id (primary key, autoincrement integer)

=item *

C<course_id>: the database id of the course the problem pool is in (foreign key)

=item *

C<pool_name>: the name of the pool (string)

=back

=cut

__PACKAGE__->table('problem_pool');

__PACKAGE__->add_columns(
	problem_pool_id => {
		data_type         => 'integer',
		size              => 16,
		is_auto_increment => 1,
	},
	course_id => {
		data_type => 'integer',
		size      => 16,
	},
	pool_name => {
		data_type => 'varchar',
		size      => 256,
	}
);

__PACKAGE__->set_primary_key('problem_pool_id');
__PACKAGE__->add_unique_constraint([qw/course_id pool_name/]);

__PACKAGE__->has_many(pool_problems => 'DB::Schema::Result::PoolProblem', 'problem_pool_id');

__PACKAGE__->belongs_to(courses => 'DB::Schema::Result::Course', 'course_id');

1;
