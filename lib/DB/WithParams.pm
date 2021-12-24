package DB::WithParams;
use warnings;
use strict;
use feature 'signatures';
no warnings qw(experimental::signatures);

use Carp;
use Array::Utils qw/array_minus intersect/;
use Scalar::Util qw/reftype/;

# Shared across subroutines, so 'our' ensures that these do not go out of scope.
our $valid_params;       # Hash of valid parameters and the regexp for the values.
our $required_params;    # Array of the required parameters.

use DB::Exception;
use Exception::Class ('DB::Exception::UndefinedParameter', 'DB::Exception::InvalidParameter',);

sub validParams ($self, $field_name) {
	$valid_params    = ref($self)->valid_params;
	$required_params = ref($self)->required_params;

	$self->validParamFields($field_name);
	$self->validateParams($field_name);
	$self->checkRequiredParams($field_name);
	return 1;
}

# Check if the param fields are valid (depending on the type of ProblemSet).

sub validParamFields ($self, $field_name) {
	return 1 unless defined($self->get_inflated_column($field_name));
	my @valid_fields = keys %$valid_params;
	my @fields       = keys %{ $self->get_inflated_column($field_name) };
	my @inter        = intersect(@fields, @valid_fields);
	if (scalar(@inter) != scalar(@fields)) {
		my @bad_fields = array_minus(@fields, @valid_fields);
		DB::Exception::UndefinedParameter->throw(
			"The following parameters are not allowed for this DB table: " . join(", ", @bad_fields));
	}
	return 1;
}

sub validateParams ($self, $field_name) {
	return 1 unless defined $self->get_inflated_column($field_name);
	for my $key (keys %{ $self->get_inflated_column($field_name) }) {
		my $re = $valid_params->{$key};
		DB::Exception::InvalidParameter->throw(message => "The parameter named $key is not valid")
			unless $self->get_inflated_column($field_name)->{$key} =~ qr/^$re$/x;
	}
	return 1;
}

sub checkRequiredParams ($self, $field_name) {
	# Depending on the data type of the $required_params, check different things.

	if (reftype($required_params) eq "HASH") {
		for my $key (keys %$required_params) {
			last unless $self->_check_params($field_name, $key, $required_params->{$key});
		}
	}
	return 1;
}

# The following is an internal subroutine to check the struture of a hashref for $required_params.

sub _check_params ($self, $field_name, $type, $value = undef) {
	my $valid = 0;    # Assume that it is not valid.
	if ($type eq "_ALL_") {
		croak "The value of the _ALL_ required type needs to be an array ref." unless reftype($value) eq "ARRAY";
		for my $el (@$value) {
			if (!defined(reftype($el))) {
				# Assume it is a string.
				$valid = grep {/^$el$/x} keys %{ $self->get_inflated_column($field_name) };
				DB::Exception::ParametersNeeded->throw(message => "Request must include: $el")
					unless $valid;
			} elsif (reftype($el) eq "HASH") {
				for my $key (keys %$el) {
					$valid = $self->_check_params($key, $el->{$key});
				}
			}
			last unless ($valid);    # If the current element in the loop is not valid, break out.
		}
	} elsif ($type eq "_ONE_OF_") {
		croak "The value of the _ONE_OF_ required type needs to be an array ref." unless reftype($value) eq "ARRAY";
		my @fields = keys %{ $self->get_inflated_column($field_name) };
		$valid = scalar(intersect(@fields, @$value)) == 1;
		DB::Exception::ParametersNeeded->throw(
			message => "Request must include exactly ONE of the following parameters: " . join(', ', @$value))
			unless $valid;
	}
	return $valid;
}

1;
