package DB::Schema::Result::User;
use base qw/DBIx::Class::Core/;
use strict;
use warnings;

__PACKAGE__->table('user');

__PACKAGE__->load_components('InflateColumn::Serializer', 'Core');

__PACKAGE__->add_columns(
	user_id => {
		data_type         => 'integer',
		size              => 16,
		is_nullable       => 0,
		is_auto_increment => 1,
	},
	username => {
		data_type   => 'varchar',
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
	is_admin => {
		data_type     => 'bool',
		is_nullable   => 0,
		default_value => 0,
	},
	login_params => {
		data_type     => 'text',
		size          => 256,
		is_nullable   => 0,
		default_value => '{}',
		serializer_class => 'JSON',
		serializer_options => { utf8 => 1 }
	}
);

__PACKAGE__->set_primary_key('user_id');
__PACKAGE__->add_unique_constraint( [qw/username/] );

__PACKAGE__->has_many( course_users => 'DB::Schema::Result::CourseUser', { 'foreign.user_id' => 'self.user_id' } );
__PACKAGE__->many_to_many( courses => 'course_users', 'courses' );

1;
