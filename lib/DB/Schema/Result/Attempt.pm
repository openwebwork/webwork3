package DB::Schema::Result::Attempt;
use DBIx::Class::Core;
use DB::WithParams;

use strict;
use warnings;

use base qw(DBIx::Class::Core DB::WithParams);

=head1 DESCRIPTION

This is the database schema for an Attempt. This stores information about
problem submissions by students.

=head2 fields

=over

=item *

C<attempt_id>: database id (primary key, autoincrement integer)

=item *

C<user_problem_id>: the database id of the user_problem (foreign key)

=item *

C<attempt_params>: a JSON object storing parameters.  These are:

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

sub valid_params {
	return {
		timestamp => q{[1-9]d+},
		scores    => q{.*},
		answer    => q{.*},
		comment   => q{.*}
	};
}

sub required_params {
	return {};
}

### this is the table that stores problems for a given Problem Set

__PACKAGE__->table('attempt');

__PACKAGE__->load_components('InflateColumn::Serializer', 'Core');

__PACKAGE__->add_columns(
	attempt_id => {
		data_type         => 'integer',
		size              => 16,
		is_nullable       => 0,
		is_auto_increment => 1,
	},
	user_problem_id => {
		data_type   => 'integer',
		size        => 16,
		is_nullable => 0,
	},
	# store scores as a JSON object
	scores => {
		data_type          => 'text',
		size               => 256,
		is_nullable        => 0,
		default_value      => '{}',
		serializer_class   => 'JSON',
		serializer_options => { utf8 => 1 }
	},
	# store answers as a JSON object
	answers => {
		data_type          => 'text',
		size               => 256,
		is_nullable        => 0,
		default_value      => '{}',
		serializer_class   => 'JSON',
		serializer_options => { utf8 => 1 }
	},
	# store comments as a JSON object
	comments => {
		data_type          => 'text',
		size               => 256,
		is_nullable        => 0,
		default_value      => '{}',
		serializer_class   => 'JSON',
		serializer_options => { utf8 => 1 }
	}
);

__PACKAGE__->set_primary_key('attempt_id');

__PACKAGE__->belongs_to(user_problem => 'DB::Schema::Result::UserProblem', 'user_problem_id');

1;
