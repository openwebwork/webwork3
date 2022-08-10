package DB::Validation;
use warnings;
use strict;
use feature 'signatures';
no warnings qw/experimental::signatures/;

use Array::Utils qw/array_minus intersect/;
use Scalar::Util qw/reftype/;

use DB::Exception;
use Exception::Class qw/
	DB::Exception::UndefinedParameter
	DB::Exception::InvalidField
	DB::Exception::FieldsNeeded
	DB::Exception::ParamFormatIncorrect
	/;

=pod

=head2 validate

Validate the parameter or date field based on the field name. This checks for valid fields and required
fields, validates the parameters, and runs any additional validation.

=cut

sub validate ($self, $field_name) {
	$self->checkForValidFields($field_name);
	$self->checkRequiredFields($field_name);
	$self->validateParams($field_name);
	$self->additional_validation($field_name);
	return 1;
}

# Check if the hash has the correct fields.
sub checkForValidFields ($self, $field_name) {
	my $params = $self->get_inflated_column($field_name);
	return 1 unless defined($params);

	my $valid_fields = $self->valid_fields($field_name);
	my @valid_fields = keys %$valid_fields;
	my @fields       = keys %$params;
	my @inter        = intersect(@fields, @valid_fields);

	if (scalar(@inter) != scalar(@fields)) {
		my @bad_fields = array_minus(@fields, @valid_fields);
		DB::Exception::InvalidField->throw(
			'The following parameters are not allowed for this DB table: ' . join(', ', @bad_fields));
	}
	return 1;
}

sub validateParams ($self, $field_name) {
	my $params       = $self->get_inflated_column($field_name);
	my $valid_fields = ref($self)->valid_fields($field_name);

	# if it doesn't exist, it is valid
	return 1 unless defined $params;

	for my $key (keys %$params) {
		my $re    = $valid_fields->{$key};
		my $valid = $re eq 'bool' ? JSON::PP::is_bool($params->{$key}) : $params->{$key} =~ qr/^$re$/x;
		DB::Exception::InvalidParameter->throw(
			message => "The parameter named $key is not valid. It has value $params->{$key}")
			unless $valid;
	}
	return 1;
}

sub checkRequiredFields ($self, $field_name) {
	my $required_fields = ref($self)->required($field_name);
	DB::Exception::ParamFormatIncorrect->throw(
		message => 'The structure of the return type of ' . ref($self) . '::required must be a hashref.')
		unless reftype($required_fields) eq 'HASH';

	for my $key (keys %$required_fields) {
		last unless $self->_check_params($field_name, $key, $required_fields->{$key});
	}
	return 1;
}

sub _check_for_all ($self, $field_name, $value = undef) {
	my $valid = 0;
	DB::Exception::ParamFormatIncorrect->throw(message => 'The value of the _ALL_ part of the required type of '
			. ref($self)
			. '::required must be an arrayref.')
		unless reftype($value) eq 'ARRAY';

	for my $el (@$value) {
		if (!defined(reftype($el))) {
			# Assume it is a string.
			$valid = grep {/^$el$/x} keys %{ $self->get_inflated_column($field_name) };
			DB::Exception::FieldsNeeded->throw(message => "Request must include: $el")
				unless $valid;
		} elsif (reftype($el) eq 'HASH') {
			for my $key (keys %$el) {
				$valid = $self->_check_params($field_name, $key, $el->{$key});
			}
		}
		last unless ($valid);    # If the current element in the loop is not valid, break out.
	}
	return;
}

sub _check_for_one_of ($self, $field_name, $value = undef) {
	DB::Exception::ParamFormatIncorrect->throw(message => 'The value of the _ONE_OF_ part of the required type of '
			. ref($self)
			. '::required must be an arrayref.')
		unless reftype($value) eq 'ARRAY';

	my @fields = keys %{ $self->get_inflated_column($field_name) };
	DB::Exception::FieldsNeeded->throw(
		message => 'Request must include exactly ONE of the following parameters: ' . join(', ', @$value))
		unless scalar(intersect(@fields, @$value)) == 1;
	return 1;
}

sub _check_for_at_least_one_of ($self, $field_name, $value = undef) {
	DB::Exception::ParamFormatIncorrect->throw(
		message => 'The value of the _AT_LEAST_ONE_OF part of the required type of '
			. ref($self)
			. '::required must be an arrayref.')
		unless reftype($value) eq 'ARRAY';

	my @fields = keys %{ $self->get_inflated_column($field_name) };
	DB::Exception::FieldsNeeded->throw(
		message => 'Request must include ONE or more of the following parameters: ' . join(', ', @$value))
		unless scalar(intersect(@fields, @$value)) >= 1;
	return 1;
}

sub _check_params ($self, $field_name, $type, $value = undef) {
	if ($type eq '_ALL_') {
		return $self->_check_for_all($field_name, $value);
	} elsif ($type eq '_ONE_OF_') {
		return $self->_check_for_one_of($field_name, $value);
	} elsif ($type eq '_AT_LEAST_ONE_OF_') {
		return $self->_check_for_at_least_one_of($field_name, $value);
	}
}

=head1 METHODS TO OVERLOAD

=head2 C<valid_fields>

subroutine that should return a hash of the valid fields for json columns

arguments: result_class, json_column_name
returns: { field_name => regex string describing contents of field_name }
	'bool' should be used in place of the regex string for boolean fields

=cut

sub valid_fields ($result_class, $) {
	return {};
}

=head2 C<additional_validation>

subroutine that should check json columns for consistency, throwing an
exception on any inconsistency rather than returning 0.

=cut

sub additional_validation ($result_class, $) {
	return 1;
}

=head2 C<required>

subroutine that should return a hashref describing the required fields in JSON columns

arguments: result_class, json_column_name
returns: { rule => \@field_names }
valid rules: '_ALL_', '_ONE_OF_', '_AT_LEAST_ONE_OF_'
	where the key describes the rule to be applied to the array of fields

=cut

sub required ($result_class, $) {
	return {};
}

1;
