package DB::Schema::Result::CourseUser;
use base qw/DBIx::Class::Core/;
use strict;
use warnings;

__PACKAGE__->table('course_user');

__PACKAGE__->load_components('InflateColumn::Serializer', 'Core');

our $VALID_PARAMS = {
	comment        => q{.*},
	useMathQuill   => q{[01]},
	useMathView    => q{[01]},
	displayMode    => q{\w+},
	status         => q{\w},
	lis_source_did => q{.*},
	useWirisEditor => q{[01]},
	showOldAnswers => q{[01]}
};

our $REQUIRED_PARAMS = {};

__PACKAGE__->add_columns(
	course_user_id => {
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
	user_id => {
		data_type   => 'integer',
		size        => 16,
		is_nullable => 0,
	},
	role => {
		data_type   => 'text',
		size        => 256,
		is_nullable => 1
	},
	section => {
		data_type   => 'integer',
		size        => 16,
		is_nullable => 1,
	},
	recitation => {
		data_type   => 'integer',
		size        => 16,
		is_nullable => 1,
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

__PACKAGE__->set_primary_key('course_user_id');
__PACKAGE__->add_unique_constraint( [qw/course_id user_id/] );

__PACKAGE__->belongs_to( users   => 'DB::Schema::Result::User',   'user_id' );
__PACKAGE__->belongs_to( courses => 'DB::Schema::Result::Course', 'course_id' );

__PACKAGE__->has_many( user_sets => 'DB::Schema::Result::UserSet', 'user_id' );

# __PACKAGE__->belongs_to( user_id => 'DB::Schema::Result::User' );
# __PACKAGE__->belongs_to( course_id => 'DB::Schema::Result::Course' );

1;
