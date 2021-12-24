package DB::WithDates;
use warnings;
use strict;
use feature 'signatures';
no warnings qw(experimental::signatures);

use Carp;
use Array::Utils qw/array_minus intersect/;
use DB::Schema::Result::ProblemSet::HWSet;
use Data::Dumper;

use DB::Exception;

our $valid_dates;       # Array of allowed/valid dates
our $required_dates;    # Array of required dates

sub validDates ($self, $type, $field_name) {
	if (defined($type)) {
		$valid_dates    = ref($self)->valid_dates($type);
		$required_dates = ref($self)->required_dates($type);
	} else {
		$valid_dates    = ref($self)->valid_dates;
		$required_dates = ref($self)->required_dates;
	}

	$self->validDateFields($field_name);
	$self->hasRequiredDateFields($field_name);
	$self->validDateFormat($field_name);
	$self->checkDates($field_name);
	return 1;
}

sub validDateFields ($self, $field_name) {
	my @fields = keys %{ $self->get_inflated_column($field_name) };
	# If this is not empty, there are illegal fields.
	my @bad_fields = array_minus(@fields, @$valid_dates);
	DB::Exception::InvalidDateField->throw(field_names => join(", ", @bad_fields))
		if (scalar(@bad_fields) != 0);

	return 1;
}

# Check that the value of each date field is valid.

sub validDateFormat ($self, $field_name) {
	for my $key (@$valid_dates) {
		next unless defined($self->get_inflated_column($field_name)->{$key});
		my $invalid_date = {};
		$invalid_date->{$key} = $self->get_inflated_column($field_name)->{$key};
		DB::Exception::InvalidDateFormat->throw(date => $invalid_date)
			unless $self->get_inflated_column($field_name)->{$key} =~ /^\d+$/x;
	}
	return 1;
}

sub hasRequiredDateFields ($self, $field_name) {
	my @fields     = keys %{ $self->get_inflated_column($field_name) };
	my @bad_fields = array_minus(@$required_dates, @fields);
	DB::Exception::RequiredDateFields->throw(message => "The field(s) " . join(", ", @bad_fields) . " must be present")
		if (scalar(@bad_fields) != 0);
	return 1;
}

sub checkDates ($self, $field_name) {
	my $dates = $self->get_inflated_column($field_name);

	my @fields      = keys %{$dates};
	my @date_fields = intersect(@fields, @$valid_dates);

	for my $i (0 .. (scalar(@date_fields) - 2)) {
		next unless defined($dates->{ $date_fields[$i] }) && defined($dates->{ $date_fields[ $i + 1 ] });
		DB::Exception::ImproperDateOrder->throw(
			message => "The date/time $date_fields[$i] must occur before $date_fields[$i+1]")
			if ($dates->{ $date_fields[$i] } > $dates->{ $date_fields[ $i + 1 ] });
	}
	return 1;
}

1;
