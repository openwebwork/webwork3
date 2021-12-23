package DB::Schema::Result::UserProblem;
use DBIx::Class::Core;
use DB::WithParams;

use strict;
use warnings;

use base qw(DBIx::Class::Core DB::WithParams);

#this is the table that stores UserProblems

## Note: we probably also need to store the problem info if it changes.

# perhaps the params will store both the problem info and the seed.

# don't allow the same problem/seed.

__PACKAGE__->table('user_problem');

__PACKAGE__->load_components('InflateColumn::Serializer', 'Core');

__PACKAGE__->add_columns(
	user_problem_id => {
		data_type         => 'integer',
		size              => 16,
		is_nullable       => 0,
		is_auto_increment => 1,
	},
	problem_id => {
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
		data_type   => 'integer',
		size        => 16,
		is_nullable => 0,
	},
	problem_version => {
		data_type   => 'integer',
		size        => 16,
		is_nullable => 1
	},
	user_problem_params => {
		data_type          => 'text',
		size               => 256,
		is_nullable        => 0,
		default_value      => '{}',
		serializer_class   => 'JSON',
		serializer_options => { utf8 => 1 }
	}
);

sub valid_params {
	return {};
}

sub required_params {
	return {};
}

__PACKAGE__->set_primary_key('user_problem_id');

__PACKAGE__->belongs_to(problems  => 'DB::Schema::Result::Problem', 'problem_id');
__PACKAGE__->belongs_to(user_sets => 'DB::Schema::Result::UserSet', 'user_set_id');

__PACKAGE__->has_many(attempts => 'DB::Schema::Result::Attempt', 'user_problem_id');

1;
