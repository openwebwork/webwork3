package DB::Schema::Result::GlobalSetting;
use base qw/DBIx::Class::Core/;
use strict;
use warnings;

=head1 DESCRIPTION

This is the database schema for the Global Course Settings.

=head2 fields

=over

=item *

C<setting_id>: database id (autoincrement integer)

=item *

C<setting_name>: the name of the setting

=item *

C<default_value>: a JSON object of the default value for the setting

=item *

C<description>: a short description of the setting

=item *

C<doc>: more extensive help documentation.

=item *

C<type>: a string representation of the type of setting (boolean, text, list, ...)

=item *

C<options>: a JSON array that stores options if the setting is an list or multilist

=item *

C<category>: the category the setting falls into

=item *

C<subcategory>: the subcategory of the setting (may be null)

=back

=cut

__PACKAGE__->table('global_setting');

__PACKAGE__->load_components('InflateColumn::Serializer', 'Core');

__PACKAGE__->add_columns(
	setting_id => {
		data_type         => 'integer',
		size              => 16,
		is_auto_increment => 1,
	},
	setting_name => {
		data_type => 'varchar',
		size      => 256,
	},
	default_value => {
		data_type          => 'text',
		default_value      => '{}',
		retrieve_on_insert => 1,
		serializer_class   => 'JSON',
		serializer_options => { utf8 => 1 }
	},
	description => {
		data_type     => 'text',
		default_value => '',
	},
	doc => {
		data_type   => 'text',
		is_nullable => 1,
	},
	type => {
		data_type     => 'varchar',
		size          => 64,
		default_value => '',
	},
	options => {
		data_type          => 'text',
		is_nullable        => 1,
		retrieve_on_insert => 1,
		serializer_class   => 'JSON',
		serializer_options => { utf8 => 1 }
	},
	category => {
		data_type     => 'varchar',
		size          => 64,
		default_value => ''
	},
	subcategory => {
		data_type   => 'varchar',
		size        => 64,
		is_nullable => 1
	}
);

__PACKAGE__->set_primary_key('setting_id');

__PACKAGE__->has_many(course_settings => 'DB::Schema::Result::CourseSetting', 'setting_id');

1;
