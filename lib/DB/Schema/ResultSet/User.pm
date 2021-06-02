=pod
 
=head1 DESCRIPTION
 
This is the functionality of a User in WeBWorK.  This package is based on 
<code>DBIx::Class::ResultSet</code>.  The basics are a CRUD for users.  
 
=cut


package DB::Schema::ResultSet::User;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

use Carp;

use List::Util qw/first/;
use Try::Tiny; 
use Data::Dump qw/dd dump/;

use DB::Utils qw/getCourseInfo getUserInfo parseUserInfo parseCourseInfo/;


=pod
=head1 getAllGlobalUsers

This gets a list of all users or users stored in the database in the <code>users</codes> table. 

=head3 input 

none 

=head3 output 

An array of courses as a <code>DBIx::Class::ResultSet::Course</code> object.  

=cut

sub getAllGlobalUsers {
	my ($self,$as_result_set) = @_;
	return $self->search({}) if $as_result_set; 
	return  $self->search({},{result_class => 'DBIx::Class::ResultClass::HashRefInflator'});
} 

=pod
=head1 getGlobalUser

Gets a single user from the <code>users</code> table. 

=head3 input 

=item * 
<code>user_info</code>, a hashref of the form <code>{user_id => 1}</code>
or <code>{login => "username"}</code>. 
=item *
<code>result_set</code>, a boolean that if true returns the user as a result set.  See below
=head3 output 

The user as either a hashref or a  <code>DBIx::Class::ResultSet::User</code> object.  the argument <code>result_set</code> 
determine which is returned.  

=cut

sub getGlobalUser {
	my ($self,$user_info,$as_result_set) = @_;
	parseUserInfo($user_info);
	my $user = $self->find($user_info);
	croak "user with info: $user_info not in the database" unless defined($user);
	return $user if $as_result_set; 
	return {$user->get_columns} if defined($user);
	
}


=pod
=head1 addGlobalUser

Add a single user to the <code>users</code> table. 

=head3 input 

<code>params</code>, a hashref including information about the user this includes:
=item * login (required)
=item * first_name
=item * last_name
=item * email
=item * student_id

=head3 output 

The user as  <code>DBIx::Class::ResultSet::User</code> object or <code>undef</code> if no user exists. 

=cut

### TODO: check that other params are legal

sub addGlobalUser {
	my ($self,$params, $as_result_set) = @_;
	croak "The parameters must include login" unless defined $params->{login};
	my $new_user = $self->create($params);
	return {$new_user->get_columns};
}

=pod
=head1 deleteGlobalUser

This deletes a single user that is stored in the database in the <code>users</codes> table. 

=head3 input 

=item *
<code>user_info</code>, a hashref of the form <code>{user_id => 1}</code>
or <code>{login => "username"}</code>. 
=item *
as_result_set, a flag to return the result as a ResultSet of a hashref. 
=head3 output 

The deleted user as a <code>DBIx::Class::ResultSet::User</code> object.  

=cut


## TODO: delete everything related to the user from all tables. 

sub deleteGlobalUser {
	my ($self,$user_info, $as_result_set) = @_;
	parseUserInfo($user_info);
	my $user_to_delete = $self->find($user_info);
	croak "The user with info $user_info does not exist" unless defined($user_to_delete);
  my $deleted_user = $user_to_delete->delete; 
	return $deleted_user if $as_result_set; 
	return {$deleted_user->get_columns};
}

=pod
=head1 updateGlobalUser

This updates a single user that is stored in the database in the <code>user</codes> table. 

=head3 input 

=item * 
<code>user_info</code>, a hashref of the form <code>{user_id => 1}</code>
or <code>{login => "username"}</code>. 
=item *
<code>params</code>, a hashref of the user parameters.   The following structure is expected:
=item - login (required)
=item - first_name
=item - last_name
=item - email
=item - student_id

=head3 output 

The updated course as a <code>DBIx::Class::ResultSet::Course</code> or a hashref.  

=cut

## TODO: check that the user_params are valid. 

sub updateGlobalUser {
	my ($self,$user_info,$user_params,$as_result_set) = @_;
	parseUserInfo($user_info); 
	my $user = $self->getGlobalUser($user_info,1); 
	croak "A user with login info $user_info does not exist" unless defined($user);
	my $updated_user = $user->update($user_params); 

	return $updated_user if $as_result_set;
	return {$user->get_columns};  
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
	my $search_params = parseCourseInfo($course_info);
	my $course_rs = $self->result_source->schema->resultset("Course");			
	my $course = $course_rs->getCourse($course_info,1);
	my @users = $self->search({'course_users.course_id'=>$course->course_id},{ prefetch => ['course_users'] });
	return \@users if $as_result_set; 
	return map { {$_->get_columns,$_->course_users->first->get_columns}; } @users; 
}

###
#
# CRUD for users in a course
#
###

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
	parseCourseInfo($course_info); 
	my $course_rs = $self->result_source->schema->resultset("Course");
	my $course = $course_rs->getCourse($course_info,1);
	my $course_id = $course->course_id; 

	my $user_info = getUserInfo($course_user_info);
	my $user = $self->find($user_info,prefetch => ["course_user"]);
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

	my $course_rs = $self->result_source->schema->resultset('Course');
	parseCourseInfo($course_info);
	my $course = $course_rs->getCourse($course_info,1); 
	
	croak "You must defined the field login in the 2nd argument" unless defined($params->{login}); 

	my $user_info = {login => $params->{login}};
	my $user = $course->users->find($user_info); 
	croak "The course with info " . $params->{login} . " already is a member of the course: $course_info"
		if defined $user;

	my $course_user_rs = $self->result_source->schema->resultset("CourseUser"); 
	
	my $user_params = {};
	for my $key ($self->result_source->columns ){
		$user_params->{$key} = $params->{$key} if defined $params->{$key};
	}

	my $new_user = $course->add_to_users($user_params,1);
	my $user_course_ids = {user_id => $new_user->user_id, course_id => $course->course_id};
	
	## just call the updateUser to fill in the fields of the new user;
	my $updated_user = $self->updateUser($user_course_ids,$params);

	return $new_user if $as_result_set;
	return {$new_user->get_columns, %{$updated_user}};
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
	my ($self,$course_user_info,$params,$as_result_set) = @_;
	my $course_rs = $self->result_source->schema->resultset("Course");
	my $course_info = getCourseInfo($course_user_info); 
	parseCourseInfo($course_info);
	my $course = $course_rs->getCourse($course_info,1); 
	croak "You must defined the field login in the 2nd argument" unless defined($params->{login}); 

	my $user_info = getUserInfo($course_user_info);
	my $user = $course->users->find($user_info); 

	croak "The course with info " . dump($user_info) . " is not a member of the course:" .
		dump($course_info) unless defined $user;


	my $course_user_rs = $self->result_source->schema->resultset("CourseUser");
	
	my $user_params = {};
	for my $key ($self->result_source->columns ){
		$user_params->{$key} = $params->{$key} if defined $params->{$key};
	}
	# update the user table
	$user = $user->update($user_params);

	my $user_course_params = {};
	
	for my $key ($course_user_rs->result_source->columns ){
		$user_course_params->{$key} = $params->{$key} if defined $params->{$key};
	}
	my $course_user = $course_user_rs
											->find({course_id => $course->course_id,user_id => $user->user_id})
											->update($user_course_params);
	
	return $user if $as_result_set;
	return {$user->get_columns,$course_user->get_columns};
}

=pod
=head2 deleteUser

This deletes a User in an existing course.  This doesn't remove the global user however. 

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
	my ($self,$course_user_info,$as_result_set) = @_;
	my $course_rs = $self->result_source->schema->resultset("Course");
	my $course_info = getCourseInfo($course_user_info); 
	parseCourseInfo($course_info);
	my $course = $course_rs->getCourse($course_info,1); 
	
	my $user_info = getUserInfo($course_user_info);
	my $user = $course->users->find($user_info); 
	croak "The course with info " . dump($user_info) . " is not a member of the course:" .
		dump($course_info) unless defined $user;

	my $course_user_rs = $self->result_source->schema->resultset("CourseUser");
	
	## get the CourseUser data from the DB
	my $deleted_course_user = $course_user_rs->find({
		course_id => $course->course_id,
		user_id => $user->user_id
	})->delete; 
	# my $deleted_course_user = $course_user_db->delete; 

	return $deleted_course_user if $as_result_set; 
	return {$user->get_columns,$deleted_course_user->get_columns}; 
	

}



1;