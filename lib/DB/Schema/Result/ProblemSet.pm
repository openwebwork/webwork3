package DB::Schema::Result::ProblemSet;
use base qw/DBIx::Class::Core/;

use strict;
use warnings;

__PACKAGE__->table('problem_set');

__PACKAGE__->load_components(qw/DynamicSubclass Core/, qw/InflateColumn::Serializer Core/);

__PACKAGE__->add_columns(
	set_id => {
		data_type         => 'integer',
		size              => 16,
		is_nullable       => 0,
		is_auto_increment => 1,
	},
	set_name => {
		data_type   => 'varchar',
		size        => 256,
		is_nullable => 0,
	},
	course_id => {
		data_type   => 'integer',
		size        => 16,
		is_nullable => 0,
	},
	type => {
		data_type     => "int",
		default_value => 1,
		size          => 8
	},
	set_visible => {
		data_type     => "boolean",
		default_value => 1,
		is_nullable   => 0
	},
	dates => { # store dates as a JSON object
		data_type     => 'text',
		size          => 256,
		is_nullable   => 0,
		default_value => '{}',
		serializer_class => 'JSON',
		serializer_options => { utf8 => 1 }
	},
	params => { # store params as a JSON object
		data_type     => 'text',
		size          => 256,
		is_nullable   => 0,
		default_value => '{}',
		serializer_class => 'JSON',
		serializer_options => { utf8 => 1 }
	}
);

#
# This defines the non-abstract classes of ProblemSets.
#

__PACKAGE__->typecast_map(
	type => {
		1 => 'DB::Schema::Result::ProblemSet::HWSet',
		2 => 'DB::Schema::Result::ProblemSet::Quiz',
		3 => 'DB::Schema::Result::ProblemSet::JITAR',
		4 => 'DB::Schema::Result::ProblemSet::ReviewSet',
	}
);

__PACKAGE__->set_primary_key('set_id');
__PACKAGE__->add_unique_constraint( [qw/course_id set_name/] );

__PACKAGE__->belongs_to( courses => 'DB::Schema::Result::Course', 'course_id' );
__PACKAGE__->has_many( problems  => 'DB::Schema::Result::Problem', 'set_id' );
__PACKAGE__->has_many( user_sets => 'DB::Schema::Result::UserSet', 'set_id' );

=head2 set_type

returns the type (HW, Quiz, JITAR, REVIEW) of the problem set

=cut

sub set_type {
	my %set_type_rev = reverse %{$DB::Schema::ResultSet::ProblemSet::SET_TYPES};
	return $set_type_rev{ shift->type };
}
1;
