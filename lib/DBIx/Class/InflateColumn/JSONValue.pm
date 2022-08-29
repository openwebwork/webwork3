package DBIx::Class::InflateColumn::JSONValue;

=pod

DBIx::Class::InflateColumn::JSONValue - encodes any value (string, number, arrray, ...)
in the form value => {}, then JSON encoded.

=cut

use strict;
use warnings;

use base qw/DBIx::Class/;
use Mojo::JSON qw/encode_json decode_json/;
use Try::Tiny;

# This is a simplified version of DBIx::Class::InflateColumn::DateTime

sub register_column {
	my ($self, $column, $info, @rest) = @_;

	$self->next::method($column, $info, @rest);
	return unless $info->{inflate_value};

	$self->inflate_column(
		$column => {
			inflate => sub {
				my $str = shift;
				# This is a bit of a hack.  It appears that sometimes the deflate isn't called on the values
				# of type string and number so they don't need to be decoded.
				try {
					my $hash = decode_json($str);
					return $hash->{value};
				} catch {
					# If the value in $str is a number, return the numerical value.
					return $str =~ /^-?(0|([1-9][0-9]*))(\.[0-9]+)?([eE][-+]?[0-9]+)?$/ ? 0 + $str : $str;
				};
			},
			deflate => sub { return encode_json({ value => shift }); }
		}
	);
	return;
}

1;
