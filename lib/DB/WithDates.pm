package DB::WithDates;

use Carp; 
use Array::Utils qw/array_minus intersect/;
use Data::Dump qw/dd/;

my $valid_dates;  # arrayref of allowed/valid dates
my $required_dates; # arrayref of required dates

sub setDateInfo {
	my ($self,$dates,$req) = @_;
	$valid_dates = $dates; 
	$required_dates = $req;
}

sub validDates {
	my $self = shift; 
	$self->validDateFields();
	$self->hasRequiredDateFields();
	$self->validDateValues();
	croak "The dates are invalid. " unless $self->checkDates();
	return 1;
}
	
sub validDateFields {
	my ($self,$valid_date_fields) = @_;
	my @fields = keys %{$self->dates}; 
	my @bad_fields = array_minus(@fields, @$valid_dates);  # if this is not empty, there are illegal fields
	if (scalar(@bad_fields) != 0) {
		croak "The field(s):  " . join(", ",@bad_fields) . " are not valid";
	}
	return 1;
}

# check that the value of each date field is valid.

sub validDateValues {
	my ($self,$valid_date_fields) = @_;
	for my $key (@$valid_date_fields) {
		next unless defined($self->dates->{$key});
		die "The date $key is not in the proper form." unless $self->dates->{$key} =~ /^\d+$/; 
	}
	return 1; 
}

sub hasRequiredDateFields {
	my ($self,$req_date_fields) = @_;
	my @fields = keys %{$self->dates}; 
	my @bad_fields = array_minus(@$req_date_fields,@fields);  
	if (scalar(@bad_fields) != 0) {
		croak "The field(s): " . join(", ",@bad_fields) . " are required for this.";
	}
	return 1; 
}

sub checkDates { 
	my $self = shift; 
	return (defined($self->dates->{reduced_scoring}) &&
			$self->dates->{open} <= $self->dates->{reduced_scoring} &&
			$self->dates->{reduced_scoring} <= $self->dates->{due} &&
			$self->dates->{due} <= $self->dates->{answer}) 
		|| ($self->dates->{open} <= $self->dates->{due} &&
				$self->dates->{due} <= $self->dates->{answer}); 
}

1;