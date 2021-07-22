package DB::Schema::Result::CourseSetting;
use base qw/DBIx::Class::Core/;
use strict;
use warnings;

use JSON;

our @VALID_DATES    = qw/open end/;
our @REQUIRED_DATES = qw//;
our $VALID   = {
	institution => q{.*},
	visible     => q{[01]}
};
our $REQUIRED = { _ALL_ => ['visible'] };

__PACKAGE__->table('course_setting');

__PACKAGE__->add_columns(
	course_setting_id => {
		data_type         => 'integer',
		size              => 16,
		is_nullable       => 0,
		is_auto_increment => 1,
	},
	course_id => {
		data_type         => 'integer',
		size              => 16,
		is_nullable       => 0,
	},
	general => {
		data_type     => 'text',
		size          => 256,
		is_nullable   => 0,
		default_value => "{}",
	},
	optional => {
		data_type     => 'text',
		size          => 256,
		is_nullable   => 0,
		default_value => "{}",
	},
	problem_set => {
		data_type     => 'text',
		size          => 256,
		is_nullable   => 0,
		default_value => "{}",
	},
	problem => {
		data_type     => 'text',
		size          => 256,
		is_nullable   => 0,
		default_value => "{}",
	},
	permissions => {
		data_type     => 'text',
		size          => 256,
		is_nullable   => 0,
		default_value => "{}",
	},
	email => {
		data_type     => 'text',
		size          => 256,
		is_nullable   => 0,
		default_value => "{}",
	}
);

__PACKAGE__->set_primary_key('course_setting_id');

__PACKAGE__->belongs_to( course => 'DB::Schema::Result::Course', 'course_id' );

for my $column (qw/general optional problem_set problem permissions email/) {
	__PACKAGE__->inflate_column(
		"$column",
		{   inflate => sub {
				decode_json shift;
			},
			deflate => sub {
				encode_json shift;
			}
		}
	);
}

	1;