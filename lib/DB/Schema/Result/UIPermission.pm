package DB::Schema::Result::UIPermission;
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

C<ui_perm_id>: database id (primary key, autoincrement integer)

=item *

C<route>: the route in the UI

=item *

C<permitted_roles>: the permitted roles for the give route.

=back

=cut

__PACKAGE__->table('ui_perm');

__PACKAGE__->load_components(qw/InflateColumn::Serializer InflateColumn::Boolean Core/);

__PACKAGE__->add_columns(
	ui_perm_id => {
		data_type         => 'integer',
		size              => 16,
		is_auto_increment => 1
	},
	route => {
		data_type => 'text',
		size      => 256,
	},
	admin_required => {
		data_type   => 'boolean',
		is_nullable => 1
	},
	allow_self_access => {
		data_type   => 'boolean',
		is_nullable => 1
	},
	allowed_roles => {
		data_type          => 'text',
		size               => 1024,
		is_nullable        => 1,
		serializer_class   => 'JSON',
		serializer_options => { utf8 => 1 }
	}
);

__PACKAGE__->set_primary_key('ui_perm_id');

1;
