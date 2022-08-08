package DB::Schema::Result::DBPermission;
use base qw/DBIx::Class::Core/;

use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

=head1 DESCRIPTION

This is the database schema for a DBPermission, storing information about which roles
are allowed to perform database tasks.

=head2 fields

=over

=item *

C<db_perm_id>: database id (primary key, autoincrement integer)

=item *

C<category>: the category (Controller module) of the task

=item *

C<action>: the name of the database task

=back

=cut

__PACKAGE__->load_components(qw/InflateColumn::Boolean/);

__PACKAGE__->table('db_perm');

__PACKAGE__->add_columns(
	db_perm_id => {
		data_type         => 'integer',
		size              => 16,
		is_nullable       => 0,
		is_auto_increment => 1
	},
	category => {
		data_type   => 'text',
		is_nullable => 0,
	},
	action => {
		data_type   => 'text',
		is_nullable => 0,
	},
	admin_required => {
		data_type   => 'boolean',
		is_nullable => 1
	},
	authenticated => {
		data_type   => 'boolean',
		is_nullable => 1
	},
	allow_self_access => {
		data_type   => 'boolean',
		is_nullable => 1
	}
);

__PACKAGE__->set_primary_key('db_perm_id');
__PACKAGE__->has_many(db_perm_roles => 'DB::Schema::Result::DBPermRole', 'db_perm_id');
__PACKAGE__->many_to_many(roles => 'db_perm_roles', 'roles');

1;
