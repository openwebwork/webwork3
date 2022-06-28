package DB::Schema::Result::DBPermRole;
use base qw/DBIx::Class::Core/;
use strict;
use warnings;

=head1 DESCRIPTION

This is the database schema for a CourseUser.  Note: this table has two purposes 1) a relationship table linking
the course and user tables (many-to-many) and 2) storing information about the user in the given course.

=head2 fields

=over

=item *

C<db_perm_role_id>: database id (primary key, autoincrement integer)

=item *

C<db_perm_id>: the database id of the permissions (foreign key)

=item *

C<role_id>: the database id of the role (foreign key)

=back

=cut

__PACKAGE__->table('db_perm_role');

__PACKAGE__->add_columns(
	db_perm_role_id => {
		data_type         => 'integer',
		size              => 16,
		is_nullable       => 0,
		is_auto_increment => 1,
	},
	db_perm_id => {
		data_type   => 'integer',
		size        => 16,
		is_nullable => 0,
	},
	role_id => {
		data_type   => 'integer',
		size        => 16,
		is_nullable => 0,
	}
);

__PACKAGE__->set_primary_key('db_perm_role_id');
__PACKAGE__->add_unique_constraint([qw/db_perm_id role_id/]);

__PACKAGE__->belongs_to(perms => 'DB::Schema::Result::DBPermission', 'db_perm_id');
__PACKAGE__->belongs_to(roles => 'DB::Schema::Result::Role',         'role_id');

1;
