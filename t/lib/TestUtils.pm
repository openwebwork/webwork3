package TestUtils;

use warnings;
use strict;
use feature 'signatures';
no warnings qw/experimental::signatures/;

use Text::CSV qw/csv/;
use DateTime::Format::Strptime;
use Mojo::JSON qw/true false/;

require Exporter;
use base qw(Exporter);
our @EXPORT_OK = qw/buildHash loadCSV removeIDs cleanUndef filterBySetType loadSchema/;

my $strp_datetime = DateTime::Format::Strptime->new(pattern => '%FT%T', on_error => 'croak');
my $strp_date     = DateTime::Format::Strptime->new(pattern => '%F',    on_error => 'croak');

=head1 DESCRIPTION

This is a collection of utilities for testing purposes

=head2 buildHash

This takes a hashref and builds up a params field and a dates field for any
field starting with PARAM: and DATE: respectively.

=cut

sub buildHash ($input, $config) {
	my $output = {};
	for my $key (keys %{$input}) {
		if ($key =~ /^([A-Z_]+):(.*)/x) {
			my $field    = lc($1);
			my $subfield = lc($2);
			$output->{$field} = {} unless defined($output->{$field});
			if ($key =~ /DATES:/) {
				# Determine if each field is a date, a datetime or other (currently a boolean).
				if (defined($input->{$key}) && $input->{$key} =~ /^\d{4}-\d{2}-\d{2}$/) {
					my $dt = $strp_date->parse_datetime($input->{$key});
					$output->{$field}->{$subfield} = $dt->epoch;
				} elsif (defined($input->{$key}) && $input->{$key} =~ /^\d{4}-\d{2}-\d{2}T\d\d:\d\d:\d\dZ$/) {
					my $dt = $strp_datetime->parse_datetime($input->{$key});
					$output->{$field}->{$subfield} = $dt->epoch;
				} elsif (grep {/^$subfield$/} @{ $config->{param_boolean_fields} }) {
					$output->{$field}->{$subfield} = int($input->{$key}) ? true : false if defined($input->{$key});
				}
			} elsif (grep { $_ eq $subfield } @{ $config->{param_boolean_fields} }) {
				$output->{$field}->{$subfield} = int($input->{$key}) ? true : false if defined($input->{$key});
			} elsif (grep { $_ eq $subfield } @{ $config->{param_non_neg_int_fields} }) {
				$output->{$field}->{$subfield} = int($input->{$key}) if defined($input->{$key});
			} elsif (grep { $_ eq $subfield } @{ $config->{param_non_neg_float_fields} }) {
				$output->{$field}->{$subfield} = 0 + $input->{$key} if defined($input->{$key});
			} else {
				$output->{$field}->{$subfield} = $input->{$key} if defined($input->{$key});
			}
		} elsif (grep { $_ eq $key } @{ $config->{boolean_fields} }) {
			$output->{$key} = defined($input->{$key}) && int($input->{$key}) ? true : false;
		} elsif (grep { $_ eq $key } @{ $config->{non_neg_int_fields} }) {
			$output->{$key} = int($input->{$key}) if defined($input->{$key});
		} elsif (grep { $_ eq $key } @{ $config->{non_neg_float_fields} }) {
			$output->{$key} = 0 + $input->{$key} if defined($input->{$key});
		} else {
			$output->{$key} = $input->{$key};
		}

	}
	return $output;
}

sub loadCSV ($filename, $config = {}) {
	my $items_from_csv = csv(in => $filename, headers => 'auto', blank_is_undef => 1);
	my @all_items      = ();
	for my $item (@$items_from_csv) {
		push(@all_items, buildHash($item, $config));
	}
	return @all_items;
}

=head2 removeIDs

Removes all of the fields of an arrayref that ends in _id

Used for testing against items from the database with all id tags removed.

=cut

# Remove any field that ends in _id except student_id and any field that has the value 'undef'.
sub removeIDs ($obj) {
	for my $key (keys %$obj) {
		delete $obj->{$key} if $key =~ /_id$/x && $key ne 'student_id';
	}
	return;
}

sub cleanUndef ($obj) {
	for my $key (keys %$obj) {
		delete $obj->{$key} unless (defined $obj->{$key});
	}
	return;
}

sub filterBySetType ($all_sets, $type, $course_name) {
	my $type_hash     = $DB::Schema::ResultSet::ProblemSet::SET_TYPES;
	my @filtered_sets = @$all_sets;

	if (defined($course_name)) {
		@filtered_sets = grep { $_->{course_name} eq $course_name } @filtered_sets;
	}
	if (defined($type)) {
		@filtered_sets = grep { $_->{set_type} eq $type } @filtered_sets;
	}

	return @filtered_sets;
}

1;
