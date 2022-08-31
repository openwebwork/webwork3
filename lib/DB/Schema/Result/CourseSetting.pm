package DB::Schema::Result::CourseSetting;
use base qw/DBIx::Class::Core/;
use strict;
use warnings;

=head1 DESCRIPTION

This is the database schema for a CourseSetting.

=head2 fields

=over

=item *

C<course_setting_id>: database id (autoincrement integer)

=item *

C<course_id>: database id of the course for the setting (foreign key)

=item *

C<global_setting_id>: database id of the global setting that the given setting is related to (foreign key)

=item *

C<value>: the value of the setting as a JSON so different types of data can be stored.

=back

=cut

__PACKAGE__->table('course_setting');

__PACKAGE__->load_components(qw/FilterColumn Core/);

__PACKAGE__->add_columns(
	course_setting_id => {
		data_type         => 'integer',
		size              => 16,
		is_nullable       => 0,
		is_auto_increment => 1,
	},
	course_id => {
		data_type => 'integer',
		size      => 16,
	},
	global_setting_id => {
		data_type => 'integer',
		size      => 16,
	},
	value => {
		data_type   => 'text',
		is_nullable => 1
	},
);

__PACKAGE__->filter_column(
	value => {
		filter_to_storage => sub {
			return JSON::MaybeXS->new({ utf8 => 1, allow_nonref => 1 })->encode($_[1] // '');
		},
		filter_from_storage => sub {
			return JSON::MaybeXS->new({ utf8 => 1, allow_nonref => 1 })->decode($_[1] // '');
		}
	}
);

__PACKAGE__->set_primary_key('course_setting_id');

__PACKAGE__->add_unique_constraint([qw/course_id global_setting_id/]);

__PACKAGE__->belongs_to(course => 'DB::Schema::Result::Course', 'course_id');

__PACKAGE__->belongs_to(global_setting => 'DB::Schema::Result::GlobalSetting', 'global_setting_id');

1;
