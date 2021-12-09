
=head1 DESCRIPTION

This is the functionality of a User in WeBWorK.  This package is based on
C<DBIx::Class::ResultSet>.  The basics are a CRUD for users.

=cut

package DB::Schema::ResultSet::User;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

use Array::Utils qw/array_minus/;
use Clone qw/clone/;

use DB::Utils qw/getCourseInfo getUserInfo removeLoginParams/;

use DB::Exception;
use Exception::Class ('DB::Exception::UserNotFound', 'DB::Exception::CourseExists', "DB::Exception::UserNotInCourse");

=head1 getAllGlobalUsers

This gets a list of all users or users stored in the database in the C<users> table.

=head3 input

none

=head3 output

An array of courses as a C<DBIx::Class::ResultSet::Course> object.

=cut

sub getAllGlobalUsers {
	my ($self, $as_result_set) = @_;
	my @users = $self->search({});
	return \@users if $as_result_set;
	return map { removeLoginParams({ $_->get_inflated_columns }); } @users;
}

=head1 getGlobalUser

Gets a single user from the C<users> table.

=head3 input

=over

=item * C<user_info>, a hashref of the form C<{ user_id => 1 }> or C<{ username => "username" }>.

=item * C<result_set>, a boolean that if true returns the user as a result set.  See below

=back

=head3 output

The user as either a hashref or a  C<DBIx::Class::ResultSet::User> object.  the argument
C<result_set> determine which is returned.

=cut

sub getGlobalUser {
	my ($self, $user_info, $as_result_set) = @_;
	my $user = $self->find(getUserInfo($user_info));
	DB::Exception::UserNotFound->throw(username => $user_info) unless defined($user);
	return $user if $as_result_set;
	my $params = { $user->get_inflated_columns };
	$params->{role} = "admin" if $user->is_admin;
	return removeLoginParams($params);
}

=head1 addGlobalUser

Add a single user to the C<users> table.

=head3 input

C<params>, a hashref including information about the user this includes:

=over

=item * username (required)

=item * first_name

=item * last_name

=item * email

=item * student_id

=back

=head3 output

The user as  C<DBIx::Class::ResultSet::User> object or C<undef> if no user exists.

=cut

### TODO: check that other params are legal

sub addGlobalUser {
	my ($self, $user_params, $as_result_set) = @_;
	DB::Exception::ParametersNeeded->throw(message => "The parameters must include username")
		unless defined($user_params->{username});
	my $params = clone($user_params);
	# remove the user_id if defined and equal to zero.
	if (defined($params->{user_id}) && $params->{user_id} == 0) {
		delete $params->{user_id};
	}

	my $new_user = $self->create($params);
	return $new_user if $as_result_set;
	return removeLoginParams({ $new_user->get_columns });
}

=head1 deleteGlobalUser

This deletes a single user that is stored in the database in the C<users> table.

=head3 input

=over

=item * C<user_info>, a hashref of the form C<{user_id => 1}> or C<{username => "username"}>.

=item * as_result_set, a flag to return the result as a ResultSet of a hashref.

=back

=head3 output

The deleted user as a C<DBIx::Class::ResultSet::User> object.

=cut

## TODO: delete everything related to the user from all tables.

sub deleteGlobalUser {
	my ($self, $user_info, $as_result_set) = @_;
	my $user_to_delete = $self->getGlobalUser($user_info, 1);

	my $deleted_user = $user_to_delete->delete;
	return $deleted_user if $as_result_set;
	return removeLoginParams({ $deleted_user->get_inflated_columns });
}

=head1 updateGlobalUser

This updates a single user that is stored in the database in the C<user> table.

=head3 input

=over

=item * C<user_info>, a hashref of the form C<{user_id => 1}> or C<{username => "username"}>.

=item * C<params>, a hashref of the user parameters.   The following structure is expected:

=over

=item - username (required)

=item - first_name

=item - last_name

=item - email

=item - student_id

=back

=back

=head3 output

The updated course as a C<DBIx::Class::ResultSet::Course> or a hashref.

=cut

## TODO: check that the user_params are valid.

sub updateGlobalUser {
	my ($self, $user_info, $user_params, $as_result_set) = @_;
	my $user     = $self->getGlobalUser($user_info, 1);
	my $user_obj = $self->new($user_params);

	my $updated_user = $user->update({ $user_obj->get_inflated_columns });
	return $updated_user if $as_result_set;
	return removeLoginParams({ $updated_user->get_inflated_columns });
}

## This clearly needs to be fixed to include encryption of the password.
# we need to decide on what encryption algorithm.

sub authenticate {
	my ($self, $username, $password) = @_;
	my $user = $self->getGlobalUser({ username => $username }, 1);
	return $user->login_params->{password} eq $password;
}

####
#
#  The following is CRUD for users in a given course
#
####

=head1 getUsers

This gets all users in a given course.

=head3 input

=over

=item * C<course_name>, a string

=back

=head3 output

An array of Users (as hashrefs) or an arrayref of C<DBIx::Class::ResultSet::User>

=cut

sub getCourseUsers {
	my ($self, $course_info, $as_result_set) = @_;
	my $course_rs = $self->result_source->schema->resultset("Course");
	my $course    = $course_rs->getCourse(getCourseInfo($course_info), 1);
	my @users     = $self->search({ 'course_users.course_id' => $course->course_id }, { prefetch => ["course_users"] });

	return \@users if $as_result_set;
	return map {
		removeLoginParams({
			# $_->get_columns,
			$_->course_users->first->get_columns,
			params => $_->course_users->first->get_inflated_column("params")
		});
	} @users;
}

=head1 getMergedUsers

This returns all users in a given course as a merge between global users
and course users.

=head3 input

=over

=item * C<course_name>, a string OR
=item * C<course_id>, a key

=back

=head3 output

An array of MergedCourseUsers (as hashrefs)

=cut

sub getMergedCourseUsers {
	my ($self, $course_info) = @_;
	my $course_rs = $self->result_source->schema->resultset("Course");
	my $course    = $course_rs->getCourse(getCourseInfo($course_info), 1);
	my @users     = $self->search({ 'course_users.course_id' => $course->course_id }, { prefetch => ["course_users"] });

	return map {
		removeLoginParams({
			$_->get_columns, $_->course_users->first->get_columns,
			params => $_->course_users->first->get_inflated_column("params")
		});
	} @users;
}

###
#
# CRUD for users in a course
#
###

=head1 getUser

This gets a single user in a given course.

=head3 input

=over

=item * C<params>, a hashref containing:

=over

=item - C<course_name>, the name of an existing course

=item - C<username>, the username of an existing user.

=back

=back

=head3 notes:
if either the course or username doesn't exist, an error will be thrown.

=head3 output

An hashref of the user.

=cut

sub getUser {
	my ($self, $course_user_info, $as_result_set) = @_;
	my $course_info = getCourseInfo($course_user_info);
	my $course      = $self->result_source->schema->resultset("Course")->getCourse($course_info, 1);
	my $course_user = $course->users->find(getUserInfo($course_user_info));
	DB::Exception::UserNotInCourse->throw(
		course_name => $course->course_name,
		username    => $course_user_info->{username}
	) unless defined($course_user);

	return $course_user if $as_result_set;
	my $user_params = { $course_user->get_columns, $course_user->course_users->first->get_columns };
	$user_params->{params} = $course_user->course_users->first->get_inflated_column("params");
	return removeLoginParams($user_params);
}

sub getCourseUser {
	my ($self, $course_user_info, $as_result_set) = @_;

	my $course = $self->result_source->schema->resultset("Course")->getCourse(getCourseInfo($course_user_info), 1);
	my $user   = $self->getGlobalUser(getUserInfo($course_user_info), 1);
	my @keys   = keys %$course_user_info;

	DB::Exception::TooManyParameters->throw(message => "Too many parameters were passed into getCourseUser")
		if (scalar(@keys) != 2);

	my $course_user = $self->result_source->schema->resultset("CourseUser")
		->find({ course_id => $course->course_id, user_id => $user->user_id });

	DB::Exception::UserNotInCourse->throw(
		message => "The user ${\$user->username} is not enrolled in the course ${\$course->course_name}")
		unless defined $course_user;

	return $course_user if $as_result_set;
	return { $course_user->get_inflated_columns };

}

##
#
# This is used to add a user to an existing course
#
##

=head2 addCourseUser

This method adds a course user to the course_users database knowing that there is
an existing user and course.

The method returns only the information in the course_user table

=cut

sub addCourseUser {
	my ($self, $course_user_params, $as_result_set) = @_;

	my $course = $self->result_source->schema->resultset("Course")->getCourse(getCourseInfo($course_user_params), 1);
	my $user   = $self->getGlobalUser(getUserInfo($course_user_params), 1);

	# check if the user is already in the given course
	my $cu = $self->result_source->schema->resultset("CourseUser")
		->find({ user_id => $user->user_id, course_id => $course->course_id });

	## remove the course_user_id if it is 0 (it's new)
	delete $course_user_params->{course_user_id}
		if defined($course_user_params->{course_user_id}) && $course_user_params->{course_user_id} == 0;

	DB::Exception::UserAlreadyInCourse->throw(
		message => "The user with username: ${\$user->username} is already in the course: ${\$course->course_name}")
		if defined($cu);

	my $params = clone($course_user_params);

	for my $key (qw/ course_id course_name username user_id/) {
		delete $params->{$key};
	}

	## still need to check params for validity.

	my $course_user = $self->result_source->schema->resultset("CourseUser")->new($params);
	$course->add_to_users({ user_id => $user->user_id });

	my $user_to_return = $self->result_source->schema->resultset("CourseUser")
		->find({ course_id => $course->course_id, user_id => $user->user_id })->update($params);

	return $user_to_return if $as_result_set;
	return { $user_to_return->get_inflated_columns };
}

=head2 updateCourseUser

This method updates the course user table

=cut

sub updateCourseUser {
	my ($self, $course_user_info, $course_user_params, $as_result_set) = @_;
	my $course_user = $self->getCourseUser($course_user_info, 1);

	my $course_user_to_return = $course_user->update($course_user_params);

	return $course_user_to_return if $as_result_set;
	return { $course_user_to_return->get_inflated_columns };

}

=head2 deleteCourseUser

This method updates the course user table

=cut

sub deleteCourseUser {
	my ($self, $course_user_info, $course_user_params, $as_result_set) = @_;
	my $course_user_to_delete = $self->getCourseUser($course_user_info, 1)->delete;

	return $course_user_to_delete if $as_result_set;
	return { $course_user_to_delete->get_inflated_columns };

}

####
#
#  The following are deprecated and just here for reference
#
###

=head1 addUser

This adds a User to an existing course

=head3 input

=over

=item * C<course_info> containing either course_name or course_id as a hashref.

=item * C<params>, a hashref containing

=over

=item - C<username>, the username of a user (required)

=item - C<first_name>, the first name of the user

=item - C<last_name>, the last name of the user

=item - C<student_id>, the student id of the user

=item - C<roles>, A listing of roles of the user (instructor, student)

=back

=back

=head3 notes

=over

=item * If both the username and course name is not included, an error will be thrown.

=item * If the course doesn't exist, an error will be thrown

=item * If the user's username already exists as a global user, an error will be thrown.

=back

=head3 output

An hashref of the added user.

=cut

# sub addUser {
# 	my ( $self, $course_info, $params, $as_result_set ) = @_;
# 	my $course = $self->result_source->schema->resultset("Course")->getCourse( $course_info, 1 );
# 	# dd $course_info;
# 	# dd $params;

# 	DB::Exception::ParametersNeeded->throw( message => "You must defined the field username in the 2nd argument" )
# 		unless defined( $params->{username} ) || defined( $params->{user_id} );

# 	my $user_info = {};
# 	if (defined($params->{user_id})) {
# 		$user_info->{user_id} = $params->{user_id};
# 	} else {
# 		$user_info->{username} = $params->{username};
# 	}

# 	my $user_exists = $course->users->find( $user_info );
# 	DB::Exception::UserAlreadyInCourse->throw( course_name => $course_info, username => $params->{username} )
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

## It doesn't look like this is used.

sub _checkCourseUser {
	my ($self, $params) = @_;
	my @fields         = keys %$params;
	my $course_user_rs = $self->result_source->schema->resultset("CourseUser");

	my @cols = $course_user_rs->result_source->columns;
	@cols = grep { !($_ =~ /_id$/x) } @cols;

	my @illegal_fields = array_minus(@fields, @cols);
	DB::Exception::ParametersNeeded->throw(
		message => "The fields " . join(", ", @illegal_fields) . " are not legal for a user.")
		unless scalar(@illegal_fields) == 0;
	return 1;
}

=head2 updateUser

This updates a User in an existing course

=head3 input

=over

=item * C<course_info> containing either course_name or course_id as a hashref.

=item * C<params>, a hashref containing

=over

=item - C<username>, the username of a user (required)

=item - C<first_name>, the first name of the user

=item - C<last_name>, the last name of the user

=item - C<student_id>, the student id of the user

=item - C<roles>, A listing of roles of the user (instructor, student)

=back

=back

=head3 notes

=over

=item * If the course doesn't exist, an error will be thrown

=item * If the username field is not defined, an error will be thrown.

=back

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

# 	DB::Excpetion::UserNotInCourse->throw(
#	course_name => $course->course_name, username => $course_user_info->{username}
#	) unless defined($user_to_update);

# 	my $updated_user = $user_to_update->update( {%$params} );    # seems like update changes $params, so make a copy.

# 	my $course_user_to_return = { $updated_user->get_inflated_columns };

# 	return $user if $as_result_set;
# 	return removeLoginParams( { $user->get_columns, %$course_user_to_return } );
# }

=head2 deleteUser

This deletes a User in an existing course.  This doesn't remove the global user however.

=head3 input

=over

=item * C<course_info> containing either course_name or course_id as a hashref.

=item * C<user_params>, a hashref containing either

=over

=item - C<username>, the username of a user

=item - C<user_id>, user_id of the user

=back

=back

=head3 notes

=over

=item * If the course doesn't exist, an error will be thrown

=item * If the username field is not defined, an error will be thrown.

=back

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
# 	DB::Exception::UserNotInCourse->throw( course_name => $course->course_name, username => $course_info->{username} )
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
