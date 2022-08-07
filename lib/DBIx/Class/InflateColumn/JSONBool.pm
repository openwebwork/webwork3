package DBIx::Class::InflateColumn::JSONBool;

=pod

This creates a DBIx::Class column of data type 'json_bool' that returns a JSON boolean.

=cut

use strict;
use warnings;
use base qw/DBIx::Class/;
use Mojo::JSON qw/true false/;

# This is a simplified version of DBIx::Class::InflateColumn::DateTime

sub register_column {
	my ($self, $column, $info, @rest) = @_;

	$self->next::method($column, $info, @rest);

	if ($info->{data_type} && $info->{data_type} eq 'json_bool') {
		$self->inflate_column(
			$column => {
				inflate => sub { return shift ? true : false; },
				deflate => sub { return shift; }
			}
		);
	}
}

1;
