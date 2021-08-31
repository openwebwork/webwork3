package DB::Schema::Result::CourseSettings;
use base qw/DBIx::Class::Core/;
use strict;
use warnings;

our @VALID_DATES    = qw/open end/;
our @REQUIRED_DATES = qw//;
our $VALID          = {
	institution => q{.*},
	visible     => q{[01]}
};
our $REQUIRED = { _ALL_ => ['visible'] };

__PACKAGE__->table('course_settings');

__PACKAGE__->load_components('InflateColumn::Serializer', 'Core');

__PACKAGE__->add_columns(
	course_settings_id => {
		data_type         => 'integer',
		size              => 16,
		is_nullable       => 0,
		is_auto_increment => 1,
	},
	course_id => {
		data_type   => 'integer',
		size        => 16,
		is_nullable => 0,
	},
	general => {
		data_type     => 'text',
		size          => 256,
		is_nullable   => 0,
		default_value => "{}",
		serializer_class => 'JSON',
		serializer_options => { utf8 => 1 }
	},
	optional => {
		data_type     => 'text',
		size          => 256,
		is_nullable   => 0,
		default_value => "{}",
		serializer_class => 'JSON',
		serializer_options => { utf8 => 1 }
	},
	problem_set => {
		data_type     => 'text',
		size          => 256,
		is_nullable   => 0,
		default_value => "{}",
		serializer_class => 'JSON',
		serializer_options => { utf8 => 1 }
	},
	problem => {
		data_type     => 'text',
		size          => 256,
		is_nullable   => 0,
		default_value => "{}",
		serializer_class => 'JSON',
		serializer_options => { utf8 => 1 }
	},
	permissions => {
		data_type     => 'text',
		size          => 256,
		is_nullable   => 0,
		default_value => "{}",
		serializer_class => 'JSON',
		serializer_options => { utf8 => 1 }
	},
	email => {
		data_type     => 'text',
		size          => 256,
		is_nullable   => 0,
		default_value => "{}",
		serializer_class => 'JSON',
		serializer_options => { utf8 => 1 }
	}
);

__PACKAGE__->set_primary_key('course_settings_id');

__PACKAGE__->belongs_to( course => 'DB::Schema::Result::Course', 'course_id' );

1;
