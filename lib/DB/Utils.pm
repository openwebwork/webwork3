package DB::Utils; 

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw/checkCourseInfo checkUserInfo getCourseInfo getUserInfo/; 

use Carp; 
use Data::Dump qw/dd/;
use List::Util qw/first/;

## checks if the course info is correct

sub checkCourseInfo {
	my ($course_info) = @_;
	my @keys = keys %$course_info; 
	croak 'The first argument may only contain 1 field' unless scalar(@keys) == 1; 
	my $key = first { $keys[0] eq $_ } ("course_id","course_name");
	croak 'The first argument must be either course_name or course_id' unless defined($key);
	return; 
	
}

## checks to ensure that the user_info is in valid form.  

## TODO: check if login contains illegal characters (spaces, other things)
##       and user_id is a positive integer.  

sub checkUserInfo {
	my ($user_info) = @_;
	my @keys = keys %$user_info; 
	croak 'The first argument may only contain 1 field' unless scalar(@keys) == 1; 
	my $key = first { $keys[0] eq $_ } ("user_id","login");
	croak 'the first argument must be either login or user_id' unless defined($key);
	return; 
	
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
