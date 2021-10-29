package DB::WithParams;
use warnings;
use strict;

use Carp;
use Array::Utils qw/array_minus intersect/;
use Data::Dump qw/dd/;
use Scalar::Util qw/reftype/;

# shared across subroutines, so 'our' ensures that these do not go out of scope
our $valid_params;       # hash of valid parameters and the regexp for the values.
our $required_params;    # array of the required parameters.

use DB::Exception;
use Exception::Class ('DB::Exception::UndefinedParameter', 'DB::Exception::InvalidParameter',);

sub validParams {
	my ($self, $type, $field_name) = @_;
	# the following stops the carping of perlcritic
	## no critic 'ProhibitStringyEval'
	## no critic 'RequireCheckingReturnValueOfEval'
	if (defined($type)) {
		eval '$valid_params = &' . ref($self) . "::valid_params($type)";
		eval '$required_params = &' . ref($self) . "::required_params($type)";
	} else {
		eval '$valid_params = &' . ref($self) . '::valid_params';
		eval '$required_params = &' . ref($self) . "::required_params";
	}

	$self->validParamFields($field_name);
	$self->validateParams($field_name);
	$self->checkRequiredParams($field_name);
	return 1;
}

# check if the param fields are valid (depending on the type of ProblemSet)

sub validParamFields {
	my ($self, $field_name) = @_;
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

sub validateParams {
	my ($self, $field_name) = @_;
	return 1 unless defined $self->get_inflated_column($field_name);
	for my $key (keys %{ $self->get_inflated_column($field_name) }) {
		my $re = $valid_params->{$key};
		DB::Exception::InvalidParameter->throw(message => "The parameter named $key is not valid")
			unless $self->get_inflated_column($field_name)->{$key} =~ qr/^$re$/x;
	}
	return 1;
}

sub checkRequiredParams {
	my $self = shift;
	## depending on the data type of the $required_params, check different things

	if (reftype($required_params) eq "HASH") {
		for my $key (keys %$required_params) {
			last unless $self->_check_params($key, $required_params->{$key});
		}
	}
	return 1;
}

## the following is an internal subroutine to check the struture of a hashref for $required_params.

sub _check_params {
	my ($self, $type, $value) = @_;
	my $valid = 0;    ## assume that it is not valid;
	if ($type eq "_ALL_") {
		croak "The value of the _ALL_ required type needs to be an array ref." unless reftype($value) eq "ARRAY";
		for my $el (@$value) {
			if (!defined(reftype($el))) {    # assume it is a string
				$valid = grep {/^$el$/x} keys %{ $self->params };
				DB::Exception::ParametersNeeded->throw(message => "Request must include: $el")
					unless $valid;
			} elsif (reftype($el) eq "HASH") {
				for my $key (keys %$el) {
					$valid = $self->_check_params($key, $el->{$key});
				}
			}
			last unless ($valid);            # if the current element in the loop is not valid, break out.
		}
	} elsif ($type eq "_ONE_OF_") {
		croak "The value of the _ONE_OF_ required type needs to be an array ref." unless reftype($value) eq "ARRAY";
		my @fields = keys %{ $self->params };
		$valid = scalar(intersect(@fields, @$value)) == 1;
		DB::Exception::ParametersNeeded->throw(
			message => "Request must include exactly ONE of the following parameters: " . join(', ', @$value))
			unless $valid;
	}
	return $valid;
}

1;
