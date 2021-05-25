package DB::Schema::ResultSet::Course;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

=pod
 
=head1 DESCRIPTION
 
This is the functionality of a Course in WeBWorK.  This package is based on 
<code>DBIx::Class::ResultSet</code>.  The basics are a CRUD for anything on the 
global courses.  
 
=cut



use Data::Dump qw/dd/;

=pod
=head1 getCourses

This gets a list of Courses stored in the database in the <code>courses</codes> table. 

=head3 input 

none

=head3 output 

An array of courses as a <code>DBIx::Class::ResultSet::Course</code> object.  

=cut

sub getCourses {
	my $self = shift;
	return map { $_->course_name} $self->search();
} 

=pod
=head1 getCourse

This gets a single course that is stored in the database in the <code>courses</codes> table. 

=head3 input 

<code>course_name</code>, a string

=head3 output 

A course as a <code>DBIx::Class::ResultSet::Course</code> object.  

=cut

sub getCourse {
	my ($self,$course_name) = @_;
	return $self->find({course_name => $course_name});
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
	my ($self,$course_name) = @_;
	## check if the course exists.  If so throw an error. 
	my $new_course = $self->create({course_name => $course_name});
	return $new_course;
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
	my ($self,$course_name) = @_;
	my $deleted_course = $self->find({course_name => $course_name})->delete;
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
	my ($self,$course_name,$course_params) = @_;
	my $course = $self->find({course_name => $course_name});
	$course->update($course_params);
	return $course; 
}


=pod
=head1 getUsers

This gets all users in a given course. 

=head3 input 

=item * 
<code>course_name</code>, a string

=head3 output 

An arrayref of Users (as hashrefs)

=cut


sub getUsers {
	my ($self,$course_name) = @_; 
	my $user_rs = $self->{result_source}{schema}->resultset("User");  
	my $course_result = $self->find({course_name => $course_name}); 
	croak "The course $course_name does not exist" unless defined $course_result; 
	my @users = $user_rs->search(
		{
			'user_params.course_id' => $course_result->course_id
		},
		{
			prefetch => ['user_params'],
		});

	return map { return {$_->get_columns, $_->user_params->first->get_columns}; } @users; 
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
	my ($self,$params) = @_;
	my $user_rs = $self->{result_source}{schema}->resultset("User"); 
	my $course_result = $self->find({course_name => $params->{course_name}}); 
	croak "The course " . $params->{course_name} . " does not exist" unless defined $course_result; 
	
	my $course_id = $self->find({course_name => $params->{course_name}})->course_id; 

	my $user = $user_rs->find({login => $params->{login}},prefetch => ["user_param"]);
	
	return {$user->get_columns,$user->user_params->first->get_columns}; 
}


=pod
=head1 addUser

This adds a User to an existing course

=head3 input 

=item * 
<code>params</code>, a hashref containing
=item -
<code>course_name</code>, the name of an existing course (required)
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


sub addUser {
	my ($self,$params) = @_;
	my $user_rs = $self->{result_source}{schema}->resultset("User");
	my $user_param_rs = $self->{result_source}{schema}->resultset("UserParam"); 
	my $course_result = $self->find({course_name => $params->{course_name}}); 
	croak "The course " . $params->{course_name} . " does not exist" unless defined $course_result; 

	my $existing_user = $course_result->users->find({login => $params->{login}});
	croak "The course with login " . $params->{login} . " already is a member of the course: " . $params->{course_name}
		if defined $existing_user;

	my $user_params = {};
	for my $key ($user_rs->result_source->columns ){
		$user_params->{$key} = $params->{$key} if defined $params->{$key};
	}
	my $new_user = $course_result->add_to_users($user_params);

	$user_params = {course_id => $course_result->course_id};
	for my $key ($user_param_rs->result_source->columns ){
		$user_params->{$key} = $params->{$key} if defined $params->{$key};
	}

	$new_user->add_to_user_params($user_params);

	return {$new_user->get_columns, $new_user->user_params->first->get_columns};

}

=pod
=head1 updateUser

This updates a User in an existing course

=head3 input 

=item * 
<code>params</code>, a hashref containing
=item -
<code>course_name</code>, the name of an existing course (required)
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


=head3 output 

An hashref of the added user. 

=cut

sub updateUser {
	my ($self,$params) = @_;
	my $user_rs = $self->{result_source}{schema}->resultset("User");
	my $user_param_rs = $self->{result_source}{schema}->resultset("UserParam"); 
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
	for my $key ($user_param_rs->result_source->columns ){
		$user_params->{$key} = $params->{$key} if defined $params->{$key};
	}

	## get the UserParam data from the DB
	my $user_param_db = $user_param_rs->find(
		{
			course_id => $course_result->course_id,
			user_id => $user_to_update->user_id
		});
	## update the database
	my $user = $user_param_db->update($user_params);


	return {$user_to_update->get_columns,$user_param_db->get_columns};
}

sub deleteUser {
	my ($self,$params) = @_;
	my $user_rs = $self->{result_source}{schema}->resultset("User");
	my $user_param_rs = $self->{result_source}{schema}->resultset("UserParam"); 
	my $course_result = $self->find({course_name => $params->{course_name}}); 
	croak "The course " . $params->{course_name} . " does not exist" unless defined $course_result; 

	my $user_to_delete = $course_result->users->find({login => $params->{login}});
	croak "The user with login: " . $params->{login} . " is not a member of the course " 
		unless defined($user_to_delete);
	
	## get the UserParam data from the DB
	my $user_param_db = $user_param_rs->find(
		{
			course_id => $course_result->course_id,
			user_id => $user_to_delete->user_id
		});
	my $deleted_user_param = $user_param_db->delete; 
	my $deleted_user = $user_to_delete->delete; 

	return {$deleted_user->get_columns,$deleted_user_param->get_columns};

}

1;