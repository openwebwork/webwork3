package TestUtils;
use parent Exporter;

use Mojo::Base -signatures;

our @EXPORT_OK = qw/removeIDs cleanUndef/;

=head1 DESCRIPTION

This is a collection of utilities for testing purposes

=over

=item removeIDs($obj)

Removes all fields of $obj that end in "_id" except the field "student_id".

Used to remove id tags from database items for comparison with JSON data that
does not have such information.

=cut

# Remove any field that ends in _id except student_id and any field that has the value 'undef'.
sub removeIDs ($obj) {
	for my $key (keys %$obj) {
		delete $obj->{$key} if $key =~ /_id$/ && $key ne 'student_id';
	}
	return;
}

=item cleanUndef($obj)

Removes all fields of $obj that are undefined.

Used to remove undefined column data from database items for comparison with
JSON data that does not have such information.

=back

=cut

sub cleanUndef ($obj) {
	for my $key (keys %$obj) {
		delete $obj->{$key} unless defined $obj->{$key};
	}
	return;
}

1;
