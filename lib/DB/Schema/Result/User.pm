package DB::Schema::Result::User;
use base qw/DBIx::Class::Core/;
use strict;
use warnings;

use JSON;

__PACKAGE__->table('user');

__PACKAGE__->add_columns(
	user_id => {
		data_type         => 'integer',
		size              => 16,
		is_nullable       => 0,
		is_auto_increment => 1,
	},
	login => {
		data_type   => 'text',
		size        => 256,
		is_nullable => 0,
	},
	first_name => {
		data_type   => 'text',
		is_nullable => 1,
	},
	last_name => {
		data_type   => 'text',
		is_nullable => 1,
	},
	email => {
		data_type   => 'text',
		is_nullable => 1,
	},
	student_id => {
		data_type   => 'text',
		is_nullable => 1,
	},
	login_params => {
		data_type     => 'text',
		size          => 256,
		is_nullable   => 0,
		default_value => "{}"
	}
);

__PACKAGE__->set_primary_key('user_id');
__PACKAGE__->add_unique_constraint( [qw/login/] );

__PACKAGE__->has_many( course_users => 'DB::Schema::Result::CourseUser', 'user_id' );
__PACKAGE__->many_to_many( courses => 'course_users', 'course_id' );

__PACKAGE__->inflate_column(
	'login_params',
	{   inflate => sub {
			decode_json shift;
		},
		deflate => sub {
			encode_json shift;
		}
	}
);
1;
