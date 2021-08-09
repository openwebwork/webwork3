package DB::TestUtils;

use warnings;
use strict;

use Text::CSV qw/csv/;
use Data::Dump qw/dd/;

require Exporter;
use base qw(Exporter);
our @EXPORT_OK = qw/buildHash loadCSV removeIDs filterBySetType/;


=pod

=head1 DESCRIPTION

This is a collection of utilities for testing purposes

=cut

=pod
=head2 buildParamHash

This takes a hashref and builds up a params field and a dates field for any
field starting with PARAM: and DATE: respectively.

=cut

sub buildHash {
	my $input = shift;
	my $output = { params => {}, dates => {} };
	for my $key (keys %{$input}) {
		if ($key =~ /^PARAM:(.*)/x) {
			$output->{params}->{$1} = $input->{$key} if defined($input->{$key});
		} elsif ($key =~ /^DATE:(.*)/x) {
			$output->{dates}->{$1} = $input->{$key} if defined($input->{$key});
		} else {
			$output->{$key} = $input->{$key};
		}
	}
	my @date_fields = keys %{$output->{dates}};
	delete $output->{dates} if (scalar(@date_fields) == 0);
	return $output;
}

sub loadCSV {
	my $filename = shift;
	my $items_from_csv = csv (in => $filename, headers => "auto", blank_is_undef => 1);
	my @all_items = ();
	for my $item (@$items_from_csv) {
		push(@all_items,buildHash($item));
	}
	return @all_items;
}

=pod

=head2 removeIDs

Removes all of the fields of an arrayref that ends in _id

Used for testing against items from the database with all id tags removed.

=cut

sub removeIDs {  # remove any field that ends in _id except student_id
	my $obj = shift;
	for my $key (keys %$obj){
		delete $obj->{$key} if $key =~ /_id$/x && $key ne 'student_id';
	}
	return;
}


sub filterBySetType {
	my ($all_sets,$type,$course_name) = @_;
	my $type_hash = $DB::Schema::ResultSet::ProblemSet::SET_TYPES;
	my @filtered_sets = @$all_sets;

	if (defined($course_name)){
		@filtered_sets = grep { $_->{course_name} eq $course_name } @filtered_sets;
	}
	if (defined($type)){
		@filtered_sets = grep { $_->{set_type} eq $type } @filtered_sets;
	}

	return @filtered_sets;
}



1;
