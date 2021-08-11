
=pod

=head1 DESCRIPTION

This is the functionality of a User in WeBWorK.  This package is based on
<code>DBIx::Class::ResultSet</code>.  The basics are a CRUD for users.

=cut

package DB::Schema::ResultSet::User;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

use Data::Dumper;
use Array::Utils qw/array_minus/;
use Clone qw/clone/;

use DB::Utils qw/getCourseInfo getUserInfo removeLoginParams/;

use DB::Exception;
use Exception::Class ( 'DB::Exception::UserNotFound', 'DB::Exception::CourseExists', "DB::Exception::UserNotInCourse" );

=pod
=head1 getAllGlobalUsers

This gets a list of all users or users stored in the database in the <code>users</codes> table.

=head3 input

none

=head3 output

An array of courses as a <code>DBIx::Class::ResultSet::Course</code> object.

=cut

sub getAllGlobalUsers {
	my ( $self, $as_result_set ) = @_;
	my @users = $self->search( {} );
	return \@users if $as_result_set;
	return map { removeLoginParams( { $_->get_inflated_columns } ); } @users;
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

The user as either a hashref or a  <code>DBIx::Class::ResultSet::User</code> object.  the argument
<code>result_set</code> determine which is returned.

=cut

sub getGlobalUser {
	my ( $self, $user_info, $as_result_set ) = @_;
	my $user = $self->find( getUserInfo($user_info) );
	DB::Exception::UserNotFound->throw( login => $user_info ) unless defined($user);
	return $user if $as_result_set;
	my $params = { $user->get_inflated_columns };
	$params->{role} = "admin" if $user->is_admin;
	return removeLoginParams($params);
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
	my ( $self, $user_params, $as_result_set ) = @_;
	DB::Exception::ParametersNeeded->throw( message => "The parameters must include login" )
		unless defined( $user_params->{login} );

	my $user_obj = $self->new($user_params);

	my $new_user = $self->create( { $user_obj->get_inflated_columns } );
	return $new_user if $as_result_set;
	return removeLoginParams( { $new_user->get_columns } );
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
	my ( $self, $user_info, $as_result_set ) = @_;
	my $user_to_delete = $self->getGlobalUser( $user_info, 1 );

	my $deleted_user = $user_to_delete->delete;
	return $deleted_user if $as_result_set;
	return removeLoginParams( { $deleted_user->get_inflated_columns } );
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
	my ( $self, $user_info, $user_params, $as_result_set ) = @_;
	my $user     = $self->getGlobalUser( $user_info, 1 );
	my $user_obj = $self->new($user_params);

	my $updated_user = $user->update( { $user_obj->get_inflated_columns } );
	return $updated_user if $as_result_set;
	return removeLoginParams( { $updated_user->get_inflated_columns } );
}

## This clearly needs to be fixed to include encryption of the password.
# we need to decide on what encryption algorithm.

sub authenticate {
	my ( $self, $username, $password ) = @_;
	my $user = $self->getGlobalUser( { login => $username }, 1 );
	return $user->login_params->{password} eq $password;
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

An array of Users (as hashrefs) or an arrayref of <code>DBIx::Class::ResultSet::User</code>

=cut

sub getCourseUsers {
	my ( $self, $course_info, $as_result_set ) = @_;
	my $course_rs = $self->result_source->schema->resultset("Course");
	my $course    = $course_rs->getCourse( getCourseInfo($course_info), 1 );
	my @users = $self->search( { 'course_users.course_id' => $course->course_id }, { prefetch => ["course_users"] } );

	return \@users if $as_result_set;
	return map {
		removeLoginParams(
			{   $_->get_columns,
				$_->course_users->first->get_columns,
				params => $_->course_users->first->get_inflated_column("params")
			}
		);
	} @users;
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
	my ( $self, $course_user_info, $as_result_set ) = @_;
	my $course_info = getCourseInfo($course_user_info);
	my $course      = $self->result_source->schema->resultset("Course")->getCourse( $course_info, 1 );
	my $course_user = $course->users->find( getUserInfo($course_user_info) );
	DB::Exception::UserNotInCourse->throw( course_name => $course->course_name, login => $course_user_info->{login} )
		unless defined($course_user);

	return $course_user if $as_result_set;
	my $user_params = { $course_user->get_columns, $course_user->course_users->first->get_columns };
	$user_params->{params} = $course_user->course_users->first->get_inflated_column("params");
	return removeLoginParams($user_params);
}



sub getCourseUser {
	my ( $self, $course_user_info, $as_result_set ) = @_;
	my $course = $self->result_source->schema->resultset("Course")
		->getCourse(getCourseInfo($course_user_info),1);
	my $user = $self->getGlobalUser(getUserInfo($course_user_info),1);
	my @keys = keys %$course_user_info;

	DB::Exception::TooManyParameters->throw(
		message => "Too many parameters were passed into getCourseUser"
	) if (scalar(@keys) != 2 );



	my $course_user = $self->result_source->schema->resultset("CourseUser")
		->find({course_id => $course->course_id, user_id => $user->user_id});

	DB::Exception::UserNotInCourse->throw(
		message => "The user ${\$user->login} is not enrolled in the course ${\$course->course_name}"
	) unless defined $course_user;

	return $course_user if $as_result_set;
	return {$course_user->get_inflated_columns};

}

##
#
# This is used to add a user to an existing course
#
##

=pod
=head2 addCourseUser

This method adds a course user to the course_users database knowing that there is
an existing user and course.

The method returns only the information in the course_user table

=cut


sub addCourseUser {
	my ( $self, $course_user_params, $as_result_set ) = @_;
	# warn "in addCourseUser";
	# warn Dumper $course_user_params;
	my $course = $self->result_source->schema->resultset("Course")
		->getCourse(getCourseInfo($course_user_params),1);
	my $user = $self->getGlobalUser(getUserInfo($course_user_params),1);

	# check if the user is already in the given course
	my $cu = $self->result_source->schema->resultset("CourseUser")
		->find({ user_id => $user->user_id, course_id => $course->course_id});
	# warn Dumper {$cu->get_inflated_columns} if $cu;
	DB::Exception::UserAlreadyInCourse->throw(
		message => "The user with username: ${\$user->login} is already in the course: ${\$course->course_name}"
	) if defined($cu);

	my $params = clone($course_user_params);

	for my $key (qw/ course_id course_name login user_id/) {
		delete $params->{$key};
	}


	## still need to check params for validity.

	my $course_user = $self->result_source->schema->resultset("CourseUser")
		->new($params);
	$course->add_to_users({user_id => $user->user_id});

	my $user_to_return = $self->result_source->schema->resultset("CourseUser")
		->find({course_id => $course->course_id, user_id => $user->user_id})
		->update($params);

	return $user_to_return if $as_result_set;
	return {$user_to_return->get_inflated_columns};
}

=pod
=head2 updateCourseUser

This method updates the course user table

=cut

sub updateCourseUser {
	my ( $self, $course_user_info, $course_user_params, $as_result_set ) = @_;
	my $course_user = $self->getCourseUser($course_user_info,1);

	my $course_user_to_return = $course_user->update($course_user_params);

	return $course_user_to_return if $as_result_set;
	return {$course_user_to_return->get_inflated_columns};

}

=pod
=head2 deleteCourseUser

This method updates the course user table

=cut

sub deleteCourseUser {
	my ( $self, $course_user_info, $course_user_params, $as_result_set ) = @_;
	my $course_user_to_delete = $self->getCourseUser($course_user_info,1)->delete;

	return $course_user_to_delete if $as_result_set;
	return {$course_user_to_delete->get_inflated_columns};

}

####
#
#  The following are deprecated and just here for reference
#
###



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


# sub addUser {
# 	my ( $self, $course_info, $params, $as_result_set ) = @_;
# 	my $course = $self->result_source->schema->resultset("Course")->getCourse( $course_info, 1 );
# 	# dd $course_info;
# 	# dd $params;

# 	DB::Exception::ParametersNeeded->throw( message => "You must defined the field login in the 2nd argument" )
# 		unless defined( $params->{login} ) || defined( $params->{user_id} );

# 	my $user_info = {};
# 	if (defined($params->{user_id})) {
# 		$user_info->{user_id} = $params->{user_id};
# 	} else {
# 		$user_info->{login} = $params->{login};
# 	}

# 	my $user_exists = $course->users->find( $user_info );
# 	DB::Exception::UserAlreadyInCourse->throw( course_name => $course_info, login => $params->{login} )
# 		if defined $user_exists;

# 	my $course_user_params = clone($params);
# 	my $user_params        = {};
# 	for my $key ( $self->result_source->columns ) {    # remove all parameters that don't fit in the user table
# 		$user_params->{$key} = $params->{$key} if defined $params->{$key};
# 		delete $course_user_params->{$key};
# 	}

# 	my $globalUser = $self->find($user_info);
# 	$globalUser    = $self->new($user_params) unless (defined($globalUser));
# 	my $new_user   = $course->add_to_users( { $globalUser->get_inflated_columns }, 1 );
# 	my $user_course_ids = { user_id => $new_user->user_id, course_id => $course->course_id };

# 	## TO CHECK: Not sure this is needed
# 	## just call the updateUser to fill in the fields of the new user;
# 	my $updated_user = $self->updateUser( $user_course_ids, $course_user_params );

# 	return $new_user if $as_result_set;
# 	return removeLoginParams( { $new_user->get_inflated_columns, %{$updated_user} } );
# }

sub _checkCourseUser {
	my ( $self, $params ) = @_;
	my @fields         = keys %$params;
	my $course_user_rs = $self->result_source->schema->resultset("CourseUser");

	my @cols = $course_user_rs->result_source->columns;
	@cols = grep { !( $_ =~ /_id$/x ) } @cols;

	my @illegal_fields = array_minus( @fields, @cols );
	DB::Exception::ParametersNeeded->throw(
		message => "The fields " . join( ", ", @illegal_fields ) . " are not legal for a user."
	) unless scalar(@illegal_fields) == 0;
	return 1;
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

# sub updateUser {
# 	my ( $self, $course_user_info, $params, $as_result_set ) = @_;
# 	my $user = $self->getUser( $course_user_info, 1 );

# 	my $course = $self->result_source->schema->resultset("Course")->getCourse( getCourseInfo($course_user_info), 1 );

# 	$self->_checkCourseUser($params);

# 	my $user_to_update = $self->result_source->schema->resultset("CourseUser")
# 		->find( { course_id => $course->course_id, user_id => $user->user_id } );

# 	DB::Excpetion::UserNotInCourse->throw( course_name => $course->course_name, login => $course_user_info->{login} )
# 		unless defined($user_to_update);

# 	my $updated_user = $user_to_update->update( {%$params} );    # seems like update changes $params, so make a copy.

# 	my $course_user_to_return = { $updated_user->get_inflated_columns };

# 	return $user if $as_result_set;
# 	return removeLoginParams( { $user->get_columns, %$course_user_to_return } );
# }

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

# sub deleteUser {
# 	my ( $self, $course_user_info, $as_result_set ) = @_;
# 	my $course_rs   = $self->result_source->schema->resultset("Course");
# 	my $course_info = getCourseInfo($course_user_info);
# 	my $course      = $course_rs->getCourse( $course_info, 1 );

# 	my $user_info = getUserInfo($course_user_info);
# 	my $user      = $course->users->find($user_info);
# 	DB::Exception::UserNotInCourse->throw( course_name => $course->course_name, login => $course_info->{login} )
# 		unless defined $user;

# 	my $course_user_rs = $self->result_source->schema->resultset("CourseUser");

# 	## get the CourseUser data from the DB
# 	my $deleted_course_user = $course_user_rs->find(
# 		{
# 			course_id => $course->course_id,
# 			user_id   => $user->user_id
# 		}
# 	)->delete;

# 	# my $deleted_course_user = $course_user_db->delete;

# 	return $deleted_course_user if $as_result_set;
# 	return removeLoginParams( { $user->get_columns, $deleted_course_user->get_inflated_columns } );

# }


1;
