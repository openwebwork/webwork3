package DB::Utils; 

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw/parseCourseInfo parseUserInfo getCourseInfo getUserInfo getSetInfo 
										updateAllFields getPoolInfo getProblemInfo/; 

use Carp; 
use Data::Dump qw/dd/;
use List::Util qw/first/;
use Scalar::Util qw/reftype/;

## checks if the course info is correct and then parses the result to be passed 
# to a database search.

sub parseCourseInfo {
	my ($course_info) = @_;
	my @keys = keys %$course_info; 
	croak 'The first argument may only contain 1 field' unless scalar(@keys) == 1; 
	my $key = first { $keys[0] eq $_ } ("course_id","course_name");
	croak 'The first argument must be either course_name or course_id' unless defined($key);

	my $search_params = {}; 
	$search_params->{"courses.course_id"} = $course_info->{course_id} if defined($course_info->{course_id});
	$search_params->{"courses.course_name"} = $course_info->{course_name} if defined($course_info->{course_name});
	
	return $search_params;
	
}

## checks to ensure that the user_info is in valid form.  

## TODO: check if login contains illegal characters (spaces, other things)
##       and user_id is a positive integer.  

sub parseUserInfo {
	my ($user_info) = @_;
	my @keys = keys %$user_info; 
	croak 'The first argument may only contain 1 field' unless scalar(@keys) == 1; 
	my $key = first { $keys[0] eq $_ } ("user_id","login");
	croak 'the first argument must be either login or user_id' unless defined($key);

	my $search_params = {}; 
	$search_params->{'users.course_id'} = $user_info->{user_id} if defined($user_info->{user_id});
	$search_params->{'users.course_name'} = $user_info->{login} if defined($login->{login});
	
	return $search_params;
	
}

sub getCourseInfo {
	return _get_info(shift, qw/course_id course_name/);
}

sub getUserInfo {
	return _get_info(shift, qw/user_id login/);
}

sub getSetInfo {
	return _get_info(shift,qw/set_id set_name/);
}

sub getPoolInfo {
	return _get_info(shift,qw/problem_pool_id pool_name/);
}

sub getProblemInfo {
	return _get_info(shift,qw/problem_number problem_id/);
}

sub _get_info {
	my ($input_info,@param_array) = @_; 
	my $output_info = {};
	for my $key (@param_array) {
		$output_info->{$key} = $input_info->{$key} if defined($input_info->{$key});
	}
	return $output_info;
}

=pod

=head1 updateAllFields

This method updates the fields of the first argument with any from the second argument. 
This returns the hashref with both the original and any replacements.  

=cut 

sub updateAllFields {
	my ($current_fields,$updated_fields) = @_; 
	my $fields_to_return = {%$current_fields};  ## make a copy of the hashref $current_fields
	for my $key (keys %$updated_fields) {
		if (reftype($updated_fields->{$key}) eq "HASH") {
			$fields_to_return->{$key} = updateAllFields($current_fields->{$key} || {},$updated_fields->{$key});
		} else {
			$fields_to_return->{$key} = defined($updated_fields->{$key}) ?
																		$updated_fields->{$key} :
																		$current_fields->{$key};
		}
	}
	return $fields_to_return;
}

1; 