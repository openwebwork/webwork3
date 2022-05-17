package DBIx::Class::InflateColumn::Serializer::Boolean::JSON;

=head1 NAME

This is based on the DBIx::Class::InflateColumn::Serializer::JSON - JSON Inflator

This includes the ability to pass boolean's back as a Mojo::JSON.

=head1 SYNOPSIS

  package MySchema::Table;
  use base 'DBIx::Class';

  __PACKAGE__->load_components('InflateColumn::Serializer', 'Core');
  __PACKAGE__->add_columns(
    'data_column' => {
      'data_type' => 'VARCHAR',
      'size'      => 255,
      'serializer_class'   => 'Boolean::JSON',
      'serializer_options' => { allow_blessed => 1, convert_blessed => 1, pretty => 1 },    # optional
    }
  );

Then in your code...

  my $struct = { 'I' => { 'am' => 'a struct' };
  $obj->data_column($struct);
  $obj->update;

And you can recover your data structure with:

  my $obj = ...->find(...);
  my $struct = $obj->data_column;

The data structures you assign to "data_column" will be saved in the database in JSON format.

Any arguments included in C<serializer_options> will be passed to the L<JSON::MaybeXS> constructor,
to be used by the JSON backend for both serializing and deserializing.

=cut

use strict;
use warnings;
use Mojo::JSON qw(decode_json encode_json);
use Carp;
use namespace::clean;

=over 4

=item get_freezer

Called by DBIx::Class::InflateColumn::Serializer to get the routine that serializes
the data passed to it. Returns a coderef.

=cut

sub get_freezer {
	my ($class, $column, $info, $args) = @_;

	my $opts = $info->{serializer_options};
	if (defined $info->{'size'}) {
		my $size = $info->{'size'};
		return sub {
			my $s = encode_json(shift);
			croak "serialization too big" if (length($s) > $size);
			return $s;
		};
	} else {
		return sub { encode_json(shift); };
	}
}

=item get_unfreezer

Called by DBIx::Class::InflateColumn::Serializer to get the routine that deserializes
the data stored in the column. Returns a coderef.

=back

=cut

sub get_unfreezer {
	my ($class, $column, $info, $args) = @_;

	my $opts           = $info->{serializer_options};
	my $boolean_fields = $opts->{boolean_fields};
	return sub {
		my $obj = decode_json(shift);
		for my $key (@$boolean_fields) {
			if (defined($obj->{$key})) {
				$obj->{$key} = $obj->{$key} ? Mojo::JSON::true : Mojo::JSON::false;
			}
		}
		return $obj;
	};
}

1;
