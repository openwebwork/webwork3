package DB::Schema::Result::PoolProblem;
use base qw/DBIx::Class::Core/;

use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

=head1 DESCRIPTION

This is the database schema for a Pool Problem, which is a problem in a Problem Pool.

=head2 fields

=over

=item *

C<pool_problem_id>: database id (primary key, autoincrement integer)

=item *

C<problem_pool_id>: the database id of the problem pool the problem  is in (foreign key)

=item *

C<params>: a object that holds the information about the pool problem

=over

=item *

C<library_id>: a database id of the problem (foreign key)

=item *

C<problem_path>: alternatively, the path of the problem

=back

=back

=head4

Note: the C<params> can only have one of the two fields

=cut

__PACKAGE__->table('pool_problem');

__PACKAGE__->load_components(qw/InflateColumn::Serializer Core/);

__PACKAGE__->add_columns(
	pool_problem_id => {
		data_type         => 'integer',
		size              => 16,
		is_auto_increment => 1,
	},
	problem_pool_id => {
		data_type   => 'integer',
		size        => 16,
		is_nullable => 0
	},
	params => {
		data_type          => 'text',
		default_value      => '{}',
		retrieve_on_insert => 1,
		serializer_class   => 'JSON',
		serializer_options => { utf8 => 1 }
	}
);

sub valid_params ($=) {
	return {
		library_id   => q{\d+},
		problem_path => q{((\w)+\/?)+}
	};
}

sub required_params ($=) {
	return { '_ONE_OF_' => [ 'library_id', 'problem_path' ] };
}

__PACKAGE__->set_primary_key('pool_problem_id');

__PACKAGE__->belongs_to(problem_pool_id => 'DB::Schema::Result::ProblemPool');

1;
