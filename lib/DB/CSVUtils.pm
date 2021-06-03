package DB::CSVUtils;

use warnings;
use strict; 

use Text::CSV qw/csv/;
use Data::Dump qw/dd/;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw/buildHash loadCSV/; 


=pod
 
=head1 DESCRIPTION
 
This is a collection of utilities to load CSV files for testing purposes

=cut

=pod
=head2 buildParamHash

This takes a hashref and builds up a params field and a dates field for any
field starting with PARAM_ and DATE_ respectively. 

=cut

sub buildHash {
	my $input = shift; 
	my $output = { params => {}, dates => {} };
	for my $key (keys %{$input}) {
		if ($key =~ /^PARAM_(.*)/) {
			$output->{params}->{$1} = $input->{$key} if defined($input->{$key});
		} elsif ($key =~ /^DATE_(.*)/) {
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

1;