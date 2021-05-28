package DB::Schema::ResultSet::Course;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

use Carp;
use Data::Dump qw/dd/;
use List::Util qw/first/;

use DB::Utils qw/getCourseInfo checkCourseInfo getUserInfo checkUserInfo/;


=pod
 
=head1 DESCRIPTION
 
This is the functionality of a Course in WeBWorK.  This package is based on 
<code>DBIx::Class::ResultSet</code>.  The basics are a CRUD for anything on the 
global courses.  
 
=cut

=pod
=head2 getCourses

This gets a list of Courses stored in the database in the <code>courses</codes> table. 

=head3 input 

<code>$as_result_set</code>, a boolean if the return is to be a result_set

=head3 output 

An array of courses as a <code>DBIx::Class::ResultSet::Course</code> object
if <code>$as_result_set</code> is true.  Otherwise an array of hash_ref.  

=cut

sub getCourses {
	my ($self, $as_result_set)  = @_; 
	my @courses = $self->search();
	return @courses if $as_result_set; 
	return map { {$_->get_columns}; } @courses; 
} 

=pod
=head1 getCourse

This gets a single course that is stored in the database in the <code>courses</codes> table. 

=head3 input 
=item *
<code>course_info</code>, a hashref containing either course_name or course_id
=item *
<code>result_set</code>, a a boolean if the return is to be a result_set

=head3 output 

The course either as a <code> DBIx::Class::ResultSet::Course</code> object or a hashref 
of the fields.  

=cut

sub getCourse {
	my ($self,$course_info,$as_result_set) = @_;
  checkCourseInfo($course_info);
	my $course = $self->find($course_info);
	die "The course with $course_info is not defined" unless $course; 
	return $course if $as_result_set; 
	return {$course->get_columns}; 
}

=pod
=head1 addCourse

Adds a single course to the database in the <code>courses</codes> table. 

=head3 input 

A set of parameters, especially a <code>course_name</code> of type string. 

=head3 output 

The added course as a <code>DBIx::Class::ResultSet::Course</code> object.  

=cut

sub addCourse {
	my ($self,$course_name,$as_result_set) = @_;
	## check if the course exists.  If so throw an error. 
	my $new_course = $self->create({course_name => $course_name});
	return $new_course if $as_result_set; 
	return {$new_course->get_columns};
}

=pod
=head1 deleteCourse

This deletes a single course that is stored in the database in the <code>courses</codes> table. 

=head3 input 

<code>course_name</code>, a string, the name of the course to be deleted.  

=head3 output 

The deleted course as a <code>DBIx::Class::ResultSet::Course</code> object.  

=cut


## TODO: delete everything related to the course from all tables. 

sub deleteCourse {
	my ($self,$course_info) = @_;
	checkCourseInfo($course_info);
	my $course_to_delete = $self->getCourse($course_info,1);

	my $deleted_course = $course_to_delete->delete;
	return {$deleted_course->get_columns};
}

=pod
=head1 updateCourse

This updates a single course that is stored in the database in the <code>courses</codes> table. 

=head3 input 

=item * 
<code>course_name</code>, a string
=item *
A hash of the course parameters to be updated.  

=head3 output 

The updated course as a <code>DBIx::Class::ResultSet::Course</code> object.  

=cut

sub updateCourse {
	my ($self,$course_info,$course_params,$as_result_set) = @_;
	checkCourseInfo($course_info);
	my $course = $self->getCourse($course_info,1);
	$course->update($course_params);
	return $course if $as_result_set; 
	return {$course->get_columns}; 
}

####
#
#  The following is CRUD for users in a given course
#
####


=pod
=head1 getUsers

This gets all users in a given course. 

=head3 input 

=item * 
<code>course_name</code>, a string

=head3 output 

An arrayref of Users (as hashrefs) or an arrayref of <code>DBIx::Class::ResultSet::User</code>

=cut


sub getUsers {
	my ($self,$course_info,$as_result_set) = @_; 
	checkCourseInfo($course_info);
	my $user_rs = $self->{result_source}{schema}->resultset("User");  
	my $course_result = $self->getCourse($course_info,1);

	my @users = $user_rs->search(
		{
			'course_users.course_id' => $course_result->course_id
		},
		{
			prefetch => ['course_users'],
		});
	return \@users if $as_result_set; 
	return map { {$_->get_columns,$_->course_users->first->get_columns}; } @users; 
}


=pod
=head1 getUser

This gets a single user in a given course. 

=head3 input 

=item * 
<code>params</code>, a hashref containing:
=item -
<code>course_name</code>, the name of an existing course
=item -
<code>login</code>, the login of an existing user.  

=head3 notes:
if either the course or login doesn't exist, an error will be thrown. 

=head3 output 

An hashref of the user. 

=cut


sub getUser {
	my ($self,$course_user_info,$as_result_set) = @_;
	my $course_info = getCourseInfo($course_user_info); 
	checkCourseInfo($course_info); 
	my $user_rs = $self->{result_source}{schema}->resultset("User"); 
	my $course_result = $self->getCourse($course_info,1);
	
	my $course_id = $course_result->course_id; 

	my $user_info = getUserInfo($course_user_info);

	my $user = $user_rs->find($user_info,prefetch => ["course_user"]);
	return $user if $as_result_set;
	return {$user->get_columns,$user->course_users->first->get_columns};
}


=pod
=head1 addUser

This adds a User to an existing course

=head3 input 

=item *
<code>course_info</code> containing either course_name or course_id as a hashref.

=item * 
<code>params</code>, a hashref containing
=item -
<code>login</code>, the login of a user (required)
=item -
<code>first_name</code>, the first name of the user
=item -
<code>last_name</code>, the last name of the user
=item -
<code>student_id</code>, the student id of the user
=item -
<code>roles</code>, A listing of roles of the user (instructor, student)

=head3 notes
=item *
If both the login and course name is not included, an error will be thrown. 
=item *
If the course doesn't exist, an error will be thrown
=item *
If the user's login already exists as a global user, an error will be thrown. 


=head3 output 

An hashref of the added user. 

=cut

## TODO: need to check for valid fields

sub addUser {
	my ($self,$course_info, $params, $as_result_set) = @_;

	checkCourseInfo($course_info);
	my $course = $self->getCourse($course_info,1); 
	
	croak "You must defined the field login in the 2nd argument" unless defined($params->{login}); 
	my $user_info = {login => $params->{login}};
	my $user = $course->users->find($user_info); 
	croak "The course with info " . $params->{login} . " already is a member of the course: $course_info"
		if defined $user;

	my $user_rs = $self->{result_source}{schema}->resultset("User");
	my $course_user_rs = $self->{result_source}{schema}->resultset("CourseUser"); 
	
	my $user_params = {};
	for my $key ($user_rs->result_source->columns ){
		$user_params->{$key} = $params->{$key} if defined $params->{$key};
	}

	my $new_user = $course->add_to_users($user_params);
	my $course_user = $course_user_rs->find({course_id=>$course->course_id, user_id => $new_user->user_id},1);

	$user_params = {};
	for my $key ($course_user_rs->result_source->columns ){
		$user_params->{$key} = $params->{$key} if defined $params->{$key};
	}

	my $updated_user = $course_user->update($user_params);

	return $new_user if $as_result_set;
	return {$new_user->get_columns, $updated_user->get_columns};
}

=pod
=head2 updateUser

This updates a User in an existing course

=head3 input 

=item *
<code>course_info</code> containing either course_name or course_id as a hashref.
=item * 
<code>params</code>, a hashref containing
=item -
<code>login</code>, the login of a user (required)
=item -
<code>first_name</code>, the first name of the user
=item -
<code>last_name</code>, the last name of the user
=item -
<code>student_id</code>, the student id of the user
=item -
<code>roles</code>, A listing of roles of the user (instructor, student)

=head3 notes
=item *
If the course doesn't exist, an error will be thrown
=item *
If the login field is not defined, an error will be thrown.


=head3 output 

An hashref of the added user. 

=cut

sub updateUser {
	my ($self,$params) = @_;
	my $user_rs = $self->{result_source}{schema}->resultset("User");
	my $course_user_rs = $self->{result_source}{schema}->resultset("CourseUser"); 
	my $course_result = $self->find({course_name => $params->{course_name}}); 
	croak "The course " . $params->{course_name} . " does not exist" unless defined $course_result; 

	my $user_to_update = $course_result->users->find({login => $params->{login}});
	croak "The user with login: " . $params->{login} . " is not a member of the course " 
		unless defined($user_to_update);

	my $user_params = {};
	for my $key ($user_rs->result_source->columns ){
		$user_params->{$key} = $params->{$key} if defined $params->{$key};
	}
	# update the user table
	$user_to_update->update($user_params);

	$user_params = {course_id => $course_result->course_id};
	for my $key ($course_user_rs->result_source->columns ){
		$user_params->{$key} = $params->{$key} if defined $params->{$key};
	}

	## get the UserParam data from the DB
	my $user_param_db = $course_user_rs->find(
		{
			course_id => $course_result->course_id,
			user_id => $user_to_update->user_id
		});
	## update the database
	my $user = $user_param_db->update($user_params);


	return {$user_to_update->get_columns,$user_param_db->get_columns};
}

=pod
=head2 deleteUser

This deletes a User in an existing course

=head3 input 

=item *
<code>course_info</code> containing either course_name or course_id as a hashref.
=item * 
<code>user_params</code>, a hashref containing either
=item -
<code>login</code>, the login of a user
=item -
<code>user_id</code>, user_id of the user

=head3 notes
=item *
If the course doesn't exist, an error will be thrown
=item *
If the login field is not defined, an error will be thrown.


=head3 output 

An hashref of the added user. 

=cut

sub deleteUser {
	my ($self,$course_info,$user_params,$as_result_set) = @_;
	checkCourseInfo($course_info);
	my $course = $self->getCourse($course_info);

	my $user_rs = $self->{result_source}{schema}->resultset("User");
	my $course_user_rs = $self->{result_source}{schema}->resultset("CourseUser"); 
	
	my $user_to_delete = $course->users->find({login => $user_params->{login}});
	croak "The user with login: " . $user_params->{login} . " is not a member of the course " 
		unless defined($user_to_delete);
	
	## get the CourseUser data from the DB
	my $course_user_db = $course_user_rs->find(
		{
			course_id => $course->course_id,
			user_id => $user_to_delete->user_id
		});
	my $deleted_course_user = $course_user_db->delete; 
	my $deleted_user = $user_to_delete->delete; 

	return $deleted_user if $as_result_set; 
	return {$deleted_user->get_columns,$deleted_course_user->get_columns}; 
	

}


####
#
#  The following is CRUD for problem sets in a given course
#
####

=pod
=head2 getProblemSets

Get all problem sets for a given course


=cut

sub getProblemSets {
	my ($self,$course_info,$set_params,$as_result_set) = @_;
	checkCourseInfo($course_info);
	my $course = $self->getCourse($course_info,1); 
	my $problem_set_rs = $self->{result_source}{schema}->resultset("ProblemSet");  
	
	my @sets = $problem_set_rs->search(
		{
			'courses.course_id' => $course->course_id
		},
		{
			prefetch => ["courses"]
		});
	return map { {$_->get_inflated_columns}; } @sets; 
}


1;