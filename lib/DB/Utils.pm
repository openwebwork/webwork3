package DB::Utils;
use warnings;
use strict;

require Exporter;
use base qw(Exporter);
our @EXPORT_OK = qw/getCourseInfo getUserInfo getSetInfo updateAllFields
	getPoolInfo getProblemInfo getPoolProblemInfo removeLoginParams/;

use Carp;
use Clone qw/clone/;
use Data::Dump qw/dd/;
use List::Util qw/first/;
use Scalar::Util qw/reftype/;

use Exception::Class ('DB::Exception::ParametersNeeded');

sub getCourseInfo {
	return _get_info(shift, qw/course_id course_name/);
}

sub getUserInfo {
	return _get_info(shift, qw/user_id username email/);
}

sub getSetInfo {
	return _get_info(shift, qw/set_id set_name/);
}

sub getPoolInfo {
	return _get_info(shift, qw/problem_pool_id pool_name/);
}

sub getProblemInfo {
	return _get_info(shift, qw/problem_number problem_id/);
}

sub getPoolProblemInfo {
	return _get_info(shift, qw/library_id pool_problem_id/);
}

# This is a generic internal subroutine to check that the info passed in contains certain fields

# $input_info is a hashref containing various search information.
# @fields is an array of the valid fields to be parsed.

sub _get_info {
	my ($input_info, @fields) = @_;
	my $output_info = {};
	for my $key (@fields) {
		$output_info->{$key} = $input_info->{$key} if defined($input_info->{$key});
	}

	DB::Exception::ParametersNeeded->throw(message => "You must pass in only one of " . join(", ", @fields) . ".")
		if scalar(keys %$output_info) > 1;
	DB::Exception::ParametersNeeded->throw(message => "You must pass exactly one of " . join(", ", @fields) . ".")
		if scalar(keys %$output_info) < 1;

	return $output_info;
}

=head1 updateAllFields

This method updates the fields of the first argument with any from the second argument.
This returns the hashref with both the original and any replacements.

=cut

sub updateAllFields {
	my ($current_fields, $updated_fields) = @_;
	my $fields_to_return = clone($current_fields);
	for my $key (keys %$updated_fields) {
		if (defined(reftype($updated_fields->{$key})) && reftype($updated_fields->{$key}) eq "HASH") {
			$fields_to_return->{$key} = updateAllFields($current_fields->{$key} || {}, $updated_fields->{$key});
		} else {
			$fields_to_return->{$key} =
				defined($updated_fields->{$key}) ? $updated_fields->{$key} : $current_fields->{$key};
		}
	}
	return $fields_to_return;
}

=head2 removeLoginParams

This removes the login_params field from a user.  There is no reason the login_params are needed
off the server.

=cut

sub removeLoginParams {
	my $params = shift;
	delete $params->{login_params};
	return $params;
}

1;
