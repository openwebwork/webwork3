package DB::Schema::Result::UserProblem;
use DBIx::Class::Core;
use DB::WithParams;

use strict;
use warnings;
use feature 'signatures';
no warnings qw(experimental::signatures);

use base qw(DBIx::Class::Core DB::WithParams);

# This is the table that stores problems for a given Problem Set.
# Note: we probably also need to store the problem info if it changes.
# Perhaps the params will store both the problem info and the seed.
# Don't allow the same problem/seed.

__PACKAGE__->table('user_problem');

__PACKAGE__->load_components('InflateColumn::Serializer', 'Core');

__PACKAGE__->add_columns(
	user_problem_id => {
		data_type         => 'integer',
		size              => 16,
		is_nullable       => 0,
		is_auto_increment => 1,
	},
	set_problem_id => {
		data_type   => 'integer',
		size        => 16,
		is_nullable => 0,
	},
	user_set_id => {
		data_type   => 'integer',
		size        => 16,
		is_nullable => 0,
	},
	seed => {
		data_type   => 'integer',
		size        => 16,
		is_nullable => 0,
	},
	status => {
		data_type   => 'decimal',
		size        => '10,5',
		is_nullable => 0,
		default_value => '0.00000'
	},
	problem_version => {
		data_type   => 'integer',
		size        => 16,
		is_nullable => 1
	},
	problem_params => {
		data_type          => 'text',
		size               => 1024,
		is_nullable        => 0,
		default_value      => '{}',
		serializer_class   => 'JSON',
		serializer_options => { utf8 => 1 }
	}
);

sub valid_params ($=) {
	return {
		# positive integers or decimals
		weight               => q{^[+]?([0-9]+(?:[\.][0-9]*)?|\.[0-9]+)$},
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
}

sub required_params ($=) {
	return {};
}

__PACKAGE__->set_primary_key('user_problem_id');

__PACKAGE__->belongs_to(problems  => 'DB::Schema::Result::SetProblem', 'set_problem_id');
__PACKAGE__->belongs_to(user_sets => 'DB::Schema::Result::UserSet',    'user_set_id');

__PACKAGE__->has_many(attempts => 'DB::Schema::Result::Attempt', 'user_problem_id');

1;
