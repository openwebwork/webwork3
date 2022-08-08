package DBIx::Class::InflateColumn::Boolean;

=pod

DBIx::Class::InflateColumn::Boolean - Auto-create JSON boolean objects from boolean columns.

=cut

use strict;
use warnings;
use base qw/DBIx::Class/;
use Mojo::JSON qw/true false/;

# This is a simplified version of DBIx::Class::InflateColumn::DateTime

sub register_column {
	my ($self, $column, $info, @rest) = @_;

	$self->next::method($column, $info, @rest);

	if ($info->{data_type} && $info->{data_type} eq 'boolean') {
		$self->inflate_column(
			$column => {
				inflate => sub { return shift ? true : false; },
				deflate => sub { return shift; }
			}
		);
	}
	return;
}

1;
