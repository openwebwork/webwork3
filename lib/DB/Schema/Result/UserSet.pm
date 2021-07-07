package DB::Schema::Result::UserSet;
use base 'DBIx::Class::Core';
use strict;
use warnings;

use JSON;

__PACKAGE__->load_components(qw/DynamicSubclass Core/);

__PACKAGE__->table('user_set');

__PACKAGE__->add_columns(
	user_set_id => {
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
	user_id => {
		data_type   => 'integer',
		size        => 16,
		is_nullable => 0,
	},
	set_version => {
		data_type     => 'integer',
		size          => 16,
		is_nullable   => 0,
		default_value => 1,
	},
	type => {
		data_type     => "int",
		default_value => 1,
		size          => 8
	},
	dates =>    # store dates as a JSON object
		{
		data_type     => 'text',
		size          => 256,
		is_nullable   => 0,
		default_value => '{}'
		},
	params =>    # store params as a JSON object
		{
		data_type     => 'text',
		size          => 256,
		is_nullable   => 0,
		default_value => '{}'
		}
);

__PACKAGE__->set_primary_key('user_set_id');
__PACKAGE__->add_unique_constraint( [qw/set_id user_id set_version/] );
__PACKAGE__->belongs_to(
	course_users => 'DB::Schema::Result::CourseUser',
	{ 'foreign.user_id' => 'self.user_id' }
);
__PACKAGE__->belongs_to( problem_sets => 'DB::Schema::Result::ProblemSet', 'set_id' );

#
# This defines the non-abstract classes of ProblemSets.
#

__PACKAGE__->typecast_map(
	type => {
		1 => 'DB::Schema::Result::UserSet::HWSet',
		2 => 'DB::Schema::Result::UserSet::Quiz',
		3 => 'DB::Schema::Result::UserSet::JITAR',
		4 => 'DB::Schema::Result::UserSet::ReviewSet',
	}
);

### Handle the params column using JSON.

__PACKAGE__->inflate_column(
	'params',
	{   inflate => sub {
			decode_json shift;
		},
		deflate => sub {
			encode_json shift;
		}
	}
);

__PACKAGE__->inflate_column(
	'dates',
	{   inflate => sub {
			decode_json shift;
		},
		deflate => sub {
			encode_json shift;
		}
	}
);
1;
