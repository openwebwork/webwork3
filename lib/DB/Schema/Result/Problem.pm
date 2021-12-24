package DB::Schema::Result::Problem;
use DBIx::Class::Core;
use DB::WithParams;

use strict;
use warnings;
use feature 'signatures';
no warnings qw(experimental::signatures);

use base qw(DBIx::Class::Core DB::WithParams);

=head1 DESCRIPTION

This is the database schema for a Problem.  Note: this table has two purposes 1) a relationship table linking
the course and user tables (many-to-many) and 2) storing information about the user in the given course.

=head2 fields

=over

=item *

C<problem_id>: database id (primary key, autoincrement integer)

=item *

C<set_id>: the database id of the set the problem is in (foreign key)

=item *

C<problem_number>: the number of the problem (integer, non-negative?)

=item *

C<problem_params>: a JSON object storing parameters.  These are:

=over

=item *

C<weight>: the weight of a problem (nonnegative integer)

=item *

C<library_id>: a database id of the problem (foreign key)

=item *

C<problem_path>: alternatively, the path of the problem

=item *

C<problem_pool_id>: if part of a problem pool, the database id of it (foreign key)

=back

=back

=head4

Note: a problem should have only one of a library_id, problem_path or problem_pool_id

=cut

sub valid_params ($=) {
	return {
		weight          => q{^[+]?([0-9]+(?:[\.][0-9]*)?|\.[0-9]+)$},    # positive integers or decimals
		library_id      => q{\d+},
		file_path       => q{.*},
		problem_pool_id => q{\d+},
		max_attempts    => q{-?\d+}
	};
}

sub required_params ($=) {
	return { '_ALL_' => [ 'weight', { '_ONE_OF_' => [ 'library_id', 'file_path', 'problem_pool_id' ] } ] };
}

# This is the table that stores problems for a given Problem Set.

__PACKAGE__->table('problem');

__PACKAGE__->load_components('InflateColumn::Serializer', 'Core');

__PACKAGE__->add_columns(
	problem_id => {
		data_type         => 'integer',
		size              => 16,
		is_nullable       => 0,
		is_auto_increment => 1,
	},
	set_id => {
		data_type   => 'integer',
		size        => 16,
		is_nullable => 0,
	},
	problem_number => {
		data_type   => 'integer',
		size        => 16,
		is_nullable => 1,
	},
	problem_version => {
		data_type     => 'integer',
		size          => 8,
		is_nullable   => 0,
		default_value => 1
	},
	# Store params as a JSON object.
	problem_params => {
		data_type          => 'text',
		size               => 256,
		is_nullable        => 0,
		default_value      => '{}',
		serializer_class   => 'JSON',
		serializer_options => { utf8 => 1 }
	}
);

__PACKAGE__->set_primary_key('problem_id');

# Maybe we don't need this.
__PACKAGE__->add_unique_constraint([qw/problem_id set_id problem_version problem_number/]);

__PACKAGE__->belongs_to(problem_set => 'DB::Schema::Result::ProblemSet', 'set_id');
__PACKAGE__->has_many(user_problems => 'DB::Schema::Result::UserProblem', 'problem_id');

1;
