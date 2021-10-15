package DB::Schema::Result::User;
use base qw/DBIx::Class::Core/;
use strict;
use warnings;

=head1 DESCRIPTION

This is the database schema for a User.

=head2 fields

=over

=item *

C<user_id>: database id (primary key, autoincrement integer)

=item *

C<username>: the username of the user (can be a login name or email)

=item *

C<first_name>: the first name of the user

=item *

C<last_name>: the last name of the user

=item *

C<email>: the email address of the user

=item *

C<student_id>: the student id (or some other identification of the user)

=item *

C<is_admin>: whether or not the user is an administrator (boolean)

=item *

C<login_params>: a JSON object storing parameters.  These are:

=over

=item *

C<method>: the method of the login/authentication

=item *

C<encrypt_password>: the encrypted password

=back

=back

=head4

Note: the login_params should be flexible enough to handle other types of login
or authentication, like LTI or LDAP

=cut

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
		data_type          => 'text',
		size               => 256,
		is_nullable        => 0,
		default_value      => '{}',
		serializer_class   => 'JSON',
		serializer_options => { utf8 => 1 }
	}
);

__PACKAGE__->set_primary_key('user_id');
__PACKAGE__->add_unique_constraint([qw/username/]);

__PACKAGE__->has_many(course_users => 'DB::Schema::Result::CourseUser', { 'foreign.user_id' => 'self.user_id' });
__PACKAGE__->many_to_many(courses => 'course_users', 'courses');

1;
