package DB::Schema::Result::CourseUser;
use base qw/DBIx::Class::Core/;
use strict;
use warnings;
use JSON;

__PACKAGE__->table('course_user');

our %VALID_PARAMS    = ( comment => '.*', );
our %REQUIRED_PARAMS = ();

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
	params =>    # store params as a JSON object
		{
		data_type     => 'text',
		size          => 256,
		is_nullable   => 0,
		default_value => '{}'
		}
);

__PACKAGE__->set_primary_key('course_user_id');
__PACKAGE__->add_unique_constraint( [qw/course_id user_id/] );

__PACKAGE__->belongs_to( user_id   => 'DB::Schema::Result::User' );
__PACKAGE__->belongs_to( course_id => 'DB::Schema::Result::Course' );

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

1;
