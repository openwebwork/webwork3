package DB::WithParams;
use warnings;
use strict;

use Carp;
use Array::Utils qw/array_minus intersect/;
use Data::Dump qw/dd/;
use Scalar::Util qw/reftype/;

my $valid_params; # hash of valid parameters and the regexp for the values.
my $required_params;  # array of the required parameters.

use DB::Exception;
use Exception::Class (
		'DB::Exception::UndefinedParameter',
		'DB::Exception::InvalidParameter',
	);

sub validParams {
	my ($self,$type) = @_;
	# the following stops the carping of perlcritic
	## no critic 'ProhibitStringyEval'
	## no critic 'RequireCheckingReturnValueOfEval'
	if (defined($type)) {
		eval '$valid_params = &' . ref($self) . "::valid_params($type)" unless $valid_params;
		eval '$required_params = &' . ref($self) . "::required_params($type)" unless $required_params;
	} else {
		eval '$valid_params = &' . ref($self) . "::valid_params" unless $valid_params;
		eval '$required_params = &' . ref($self) . "::required_params" unless $required_params;
	}

	$self->validParamFields();
	$self->validateParams();
	$self->checkRequiredParams();
	return 1;
}

# check if the param fields are valid (depending on the type of ProblemSet)

sub validParamFields {
	my $self = shift;
	return 1 unless defined($self->params);
	my @valid_fields = keys %$valid_params;
	my @fields = keys %{$self->params};
	my @inter = intersect(@fields,@valid_fields);
	if (scalar(@inter) != scalar(@fields)) {
		my @bad_fields = array_minus(@fields, @valid_fields);
		DB::Exception::UndefinedParameter->throw(field_names=>join(", ",@bad_fields));
	}
	return 1;
}

sub validateParams {
	my $self = shift;
	return 1 unless defined $self->params;
	for my $key (keys %{$self->params}){
		my $re = $valid_params->{$key};
		DB::Exception::InvalidParameter->throw(field_names => $key) unless $self->params->{$key} =~ qr/^$re$/x;
	}
	return 1;
}

sub checkRequiredParams {
	my $self = shift;
	## depending on the data type of the $required_params, check different things

	if (reftype($required_params) eq "HASH") {
		for my $key (keys %$required_params) {
			$self->_check_params($key,$required_params->{$key});
		}
	}
	return 1;
}

## the following is an internal subroutine to check the struture of a hashref for $required_params.

sub _check_params {
	my ($self,$type,$value) = @_;
	if ($type eq "_ALL_") {
		croak "The value of the _ALL_ required type needs to be an array ref." unless reftype($value) eq "ARRAY";
		my $valid = "";  ## assume that it is not valid;
		for my $el (@$value) {
			if(! defined(reftype($el))) { # assume it is a string
				$valid = grep {/^$el$/x } @$value;
			} elsif( reftype($el) eq "HASH") {
				for my $key (keys %$el) {
					$valid = $self->_check_params($key,$el->{$key});
				}
			}
			next unless ($valid); # if the current element in the loop is not valid, break out.
		}
	} elsif ($type eq "_ONE_OF_") {
		croak "The value of the _ONE_OF_ required type needs to be an array ref." unless reftype($value) eq "ARRAY";
		my @fields = keys %{$self->params};
		return scalar(intersect(@fields,@$value)) == 1;
	}
	return 1;
}

1;
