package DB::Schema::Result::UserProblem;
use DBIx::Class::Core;

use strict;
use warnings;
use feature 'signatures';
no warnings qw/experimental::signatures/;

use base qw/DBIx::Class::Core DB::Validation/;

# This is the table that stores problems for a given Problem Set.
# Note: we probably also need to store the problem info if it changes.
# Perhaps the params will store both the problem info and the seed.
# Don't allow the same problem/seed.

__PACKAGE__->table('user_problem');

__PACKAGE__->load_components(qw/InflateColumn::Serializer Core/);

__PACKAGE__->add_columns(
	user_problem_id => {
		data_type         => 'integer',
		size              => 16,
		is_auto_increment => 1,
	},
	set_problem_id => {
		data_type => 'integer',
		size      => 16,
	},
	user_set_id => {
		data_type => 'integer',
		size      => 16,
	},
	seed => {
		data_type => 'integer',
		size      => 16,
	},
	status => {
		data_type          => 'decimal',
		size               => '10,5',
		default_value      => '0.00000',
		retrieve_on_insert => 1,
	},
	problem_version => {
		data_type          => 'integer',
		size               => 16,
		is_nullable        => 1,
		default_value      => 1,
		retrieve_on_insert => 1,
	},
	problem_params => {
		data_type          => 'text',
		size               => 1024,
		default_value      => '{}',
		retrieve_on_insert => 1,
		serializer_class   => 'JSON',
		serializer_options => { utf8 => 1 }
	}
);

__PACKAGE__->set_primary_key('user_problem_id');

__PACKAGE__->belongs_to(problems  => 'DB::Schema::Result::SetProblem', 'set_problem_id');
__PACKAGE__->belongs_to(user_sets => 'DB::Schema::Result::UserSet',    'user_set_id');

__PACKAGE__->has_many(attempts => 'DB::Schema::Result::Attempt', 'user_problem_id');

=head2 C<valid_fields>

subroutine that returns a hash of the valid fields for json columns

=cut

sub valid_fields ($self, $column_name) {
	if ($column_name eq 'problem_params') {
		return {
			# positive integers or decimals
			weight               => q{^\d+\.?\d*$},
			library_id           => q{\d+},
			file_path            => q{.*},
			problem_pool_id      => q{\d+},
			max_attempts         => q{^-?\d+$},
			att_to_open_children => q{\d+},
			last_answer          => q{^.*$},
			prPeriod             => q{^-?\d+$},
			prCount              => q{\d+},
			counts_parent_grade  => 'bool',
			attempted            => q{\d+},
			num_correct          => q{\d+},
			num_incorrect        => q{\d+},
			showMeAnotherCount   => q{\d+}
		};
	} else {
		return {};
	}
}

1;
