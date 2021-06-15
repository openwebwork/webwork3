package DB::WithDates;

use Carp; 
use Array::Utils qw/array_minus intersect/;
use Data::Dump qw/dd/;

use Exception::Class (
		'DB::Exception::InvalidDateField',
		'DB::Exception::InvalidDateFormat',
		'DB::Exception::RequiredDateFields',
		'DB::Exception::ImproperDateOrder'
	);

my @valid_dates;  # array of allowed/valid dates
my @required_dates; # array of required dates

# sub setDateInfo {
# 	my ($self,$dates,$req) = @_;
# 	$valid_dates = $dates; 
# 	$required_dates = $req;
# }

sub validDates {
	my $self = shift; 
	eval ('@valid_dates = @' . ref($self) . "::VALID_DATES") unless @valid_dates;
	eval ('@required_dates = @' . ref($self) . "::REQUIRED_DATES") unless @required_dates;
	
	## TODO: check that @valid_dates and @required_dates are defined; 
	$self->validDateFields();
	$self->hasRequiredDateFields();
	$self->validDateFormat();
	$self->checkDates();
	return 1;
}
	
sub validDateFields {
	my $self = shift; 
	my @fields = keys %{$self->dates}; 
	my @bad_fields = array_minus(@fields, @valid_dates);  # if this is not empty, there are illegal fields
	DB::Exception::InvalidDateField->throw(field_names=> join(", ",@bad_fields))
		if (scalar(@bad_fields) != 0);

	return 1;
}

# check that the value of each date field is valid.

sub validDateFormat {
	my $self = shift; 
	for my $key (@valid_dates) {
		next unless defined($self->dates->{$key});
		my $invalid_date  = {};
		$invalid_date->{$key} = $self->dates->{$key};
		DB::Exception::InvalidDateFormat->throw(date => $invalid_date) unless $self->dates->{$key} =~ /^\d+$/;
	}
	return 1; 
}

sub hasRequiredDateFields {
	my $self = shift;
	my @fields = keys %{$self->dates}; 
	my @bad_fields = array_minus(@required_dates,@fields);  
	DB::Exception::RequiredDateFields->throw(field_names=>join(", ",@bad_fields)) if (scalar(@bad_fields) != 0);
	return 1; 
}

sub checkDates { 
	my $self = shift; 
	my @date_fields = keys %{$self->dates}; 
	my $dates_in_order = 1; # assume the dates are in order;
	for my $i (0..(scalar(@valid_dates)-2)){
		next unless defined($self->dates->{$valid_dates[$i]}) && defined($self->dates->{$valid_dates[$i+1]});
		DB::Exception::ImproperDateOrder->throw(field_names=>$valid_dates[$i] . ", " . $valid_dates[$i+1])
			unless ($self->dates->{$valid_dates[$i]} <= $self->dates->{$valid_dates[$i+1]});
	}
	return $dates_in_order; 
}

1;