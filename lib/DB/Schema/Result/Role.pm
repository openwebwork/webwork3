package DB::Schema::Result::Role;
use base qw/DBIx::Class::Core/;

use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

=head1 DESCRIPTION

This is the database schema for a Role.

=head2 fields

=over

=item *

C<role_id>: database id (primary key, autoincrement integer)

=item *

C<role_name>: the name of the role

=back

=cut

__PACKAGE__->table('role');

__PACKAGE__->add_columns(
	role_id => {
		data_type         => 'integer',
		size              => 16,
		is_nullable       => 0,
		is_auto_increment => 1
	},
	role_name => {
		data_type   => 'text',
		size        => 64,
		is_nullable => 0,
	}
);

__PACKAGE__->set_primary_key('role_id');
__PACKAGE__->add_unique_constraint([qw/role_name/]);

__PACKAGE__->has_many(db_perm_roles => 'DB::Schema::Result::DBPermRole', 'role_id');
__PACKAGE__->many_to_many(db_perms => 'db_perm_roles', 'db_perms');

1;
