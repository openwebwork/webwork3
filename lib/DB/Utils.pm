package DB::Utils; 

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw/parseCourseInfo parseUserInfo getCourseInfo getUserInfo getSetInfo/; 

use Carp; 
use Data::Dump qw/dd/;
use List::Util qw/first/;

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
  my $course_user_info = shift; 
  my $course_info = {};
  for my $key (qw/course_id course_name/){
    $course_info->{$key} = $course_user_info->{$key} if defined($course_user_info->{$key});
  }
  return $course_info; 
}

sub getUserInfo {
  my $course_user_info = shift; 
  my $user_info = {};
  for my $key (qw/user_id login/){
    $user_info->{$key} = $course_user_info->{$key} if defined($course_user_info->{$key});
  }
  return $user_info; 
}

sub getSetInfo {
	my $course_set_info = shift; 
	my $set_info = {};
	for my $key (qw/set_id name/) {
		$set_info->{$key} = $course_set_info->{$key} if defined($course_set_info->{$key});
	}
	return $set_info; 
}

1; 