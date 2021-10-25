package DB::WithDates;
use warnings;
use strict;

use Carp;
use Array::Utils qw/array_minus intersect/;
use Data::Dumper;

use DB::Exception;

our $valid_dates;       # array of allowed/valid dates
our $required_dates;    # array of required dates

sub validDates {
	my ($self, $type, $field_name) = @_;
	# the following stops the carping of perlcritic
	## no critic 'ProhibitStringyEval'
	## no critic 'RequireCheckingReturnValueOfEval'
	if (defined($type)) {
		eval '$valid_dates = &' . ref($self) . "::valid_dates($type)";
		eval '$required_dates = &' . ref($self) . "::required_dates($type)";
	} else {
		eval '$valid_dates = &' . ref($self) . "::valid_dates";
		eval '$required_dates = &' . ref($self) . "::required_dates";
	}

	$self->validDateFields($field_name);
	$self->hasRequiredDateFields($field_name);
	$self->validDateFormat($field_name);
	$self->checkDates($field_name);
	return 1;
}

sub validDateFields {
	my ($self, $field_name) = @_;
	my @fields     = keys %{ $self->get_inflated_column($field_name) };
	my @bad_fields = array_minus(@fields, @$valid_dates);               # if this is not empty, there are illegal fields
	DB::Exception::InvalidDateField->throw(field_names => join(", ", @bad_fields))
		if (scalar(@bad_fields) != 0);

	return 1;
}

# check that the value of each date field is valid.

sub validDateFormat {
	my ($self, $field_name) = @_;
	for my $key (@$valid_dates) {
		next unless defined($self->get_inflated_column($field_name)->{$key});
		my $invalid_date = {};
		$invalid_date->{$key} = $self->get_inflated_column($field_name)->{$key};
		DB::Exception::InvalidDateFormat->throw(date => $invalid_date)
			unless $self->get_inflated_column($field_name)->{$key} =~ /^\d+$/x;
	}
	return 1;
}

sub hasRequiredDateFields {
	my ($self, $field_name) = @_;
	my @fields     = keys %{ $self->get_inflated_column($field_name) };
	my @bad_fields = array_minus(@$required_dates, @fields);
	DB::Exception::RequiredDateFields->throw(message => "The field(s) " . join(", ", @bad_fields) . " must be present")
		if (scalar(@bad_fields) != 0);
	return 1;
}

sub checkDates {
	my ($self, $field_name) = @_;
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
