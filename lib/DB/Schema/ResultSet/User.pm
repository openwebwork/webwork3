
=head1 DESCRIPTION

This is the functionality of a User in WeBWorK.  This package is based on
C<DBIx::Class::ResultSet>.  The basics are a CRUD for users.

=cut

package DB::Schema::ResultSet::User;

use strict;
use warnings;
use feature 'signatures';
no warnings qw(experimental::signatures);

use base 'DBIx::Class::ResultSet';

use Array::Utils qw/array_minus/;
use Clone qw/clone/;

use DB::Utils qw/getCourseInfo getUserInfo removeLoginParams/;

use DB::Exception;
use Exception::Class (
	'DB::Exception::UserNotFound',
	'DB::Exception::CourseAlreadyExists',
	"DB::Exception::UserNotInCourse"
);

=head1 getAllGlobalUsers

This gets a list of all users or users stored in the database in the C<users> table.

=head3 input

none

=head3 output

An array of courses as a C<DBIx::Class::ResultSet::Course> object.

=cut

sub getAllGlobalUsers ($self, %args) {
	my @users = $self->search({});
	return \@users if $args{as_result_set};
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

sub getGlobalUser ($self, %args) {
	my $user = $self->find(getUserInfo($args{info}));
	DB::Exception::UserNotFound->throw(message => "The user with "
			. ($args{info}->{username} ? "username '"            : "user_id '")
			. ($args{info}->{username} ? $args{info}->{username} : $args{info}->{user_id})
			. "' does not exist ")
		unless defined($user);
	return $user if $args{as_result_set};
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

# TODO: Check that other params are legal.

sub addGlobalUser ($self, %args) {

	DB::Exception::ParametersNeeded->throw(message => "The parameters must include username")
		unless defined($args{params}->{username});
	my $params = clone($args{params});
	# remove the user_id if defined and equal to zero.
	delete $params->{user_id} if (defined($params->{user_id}) && $params->{user_id} == 0);

	# Check that the username is valid
	DB::Exception::InvalidParameter->throw(message => "The username '$params->{username}' is not valid.")
		unless $params->{username} =~ /^[\w@\d.]+$/;

	my $new_user = $self->create($params);
	return $new_user if $args{as_result_set};
	return removeLoginParams({ $new_user->get_inflated_columns });
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

# TODO: Delete everything related to the user from all tables.

sub deleteGlobalUser ($self, %args) {
	my $user_to_delete = $self->getGlobalUser(info => $args{info}, as_result_set => 1);

	my $deleted_user = $user_to_delete->delete;
	return $deleted_user if $args{as_result_set};
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

# TODO: Check that the user_params are valid.

sub updateGlobalUser ($self, %args) {
	my $user     = $self->getGlobalUser(info => $args{info}, as_result_set => 1);
	my $user_obj = $self->new($args{params});

	my $updated_user = $user->update({ $user_obj->get_inflated_columns });
	return $updated_user if $args{as_result_set};
	return removeLoginParams({ $updated_user->get_inflated_columns });
}

=head1 getGlobalCourseUsers

This gets a list of all global users in a given course

=head3 input

=item * C<info>, a hashref of the form C<{course_id => 1}> or C<{course_name => "coursename"}>.

=head3 output

An array of users as a C<DBIx::Class::ResultSet::User> object.

=cut

sub getGlobalCourseUsers ($self, %args) {
	my $course = $self->rs("Course")->getCourse(info => getCourseInfo($args{info}), as_result_set => 1);
	my @users  = $self->search(
		{
			'course_users.course_id' => $course->course_id
		},
		{
			prefetch => qw/course_users/
		}
	);
	return \@users if $args{as_result_set};
	return map { removeLoginParams({ $_->get_inflated_columns }); } @users;
}

# This clearly needs to be fixed to include encryption of the password.
# We need to decide on what encryption algorithm.

sub authenticate ($self, $username, $password) {
	my $user = $self->getGlobalUser(info => { username => $username }, as_result_set => 1);
	return $user->login_params->{password} eq $password;
}

#  The following is CRUD for users in a given course

=head1 getCourseUsers

This gets all users in a given course.

=head3 input

A hash of input values.

=over

=item * C<info>, either a course name or course_id.

For example, C<{ course_name => 'Precalculus'}> or C<{course_id => 3}>

=item * C<merged>, a boolean on whether to return a merged user or course user

=item * C<as_result_set>, a boolean.  If true this an object of type
C<DBIx::Class::ResultSet::User>
if false, a hashrefs of a course user.

=back

=head3 output

An array of a hashref of a course user or merged course user
or an arrayref of C<DBIx::Class::ResultSet::User>

=cut

sub getCourseUsers ($self, %args) {
	my $course       = $self->rs("Course")->getCourse(info => getCourseInfo($args{info}), as_result_set => 1);
	my @course_users = $self->rs("CourseUser")->search({
		'course_id' => $course->course_id
	});

	return \@course_users if $args{as_result_set};

	my @users_to_return = ();
	for my $course_user (@course_users) {
		my $params = $args{merged} ? _getMergedUser($course_user) : _getCourseUser($course_user);
		push(@users_to_return, $params);
	}
	return @users_to_return;
}

# CRUD for users in a course

=head1 getCourseUser

This gets a single user in a given course.

=head3 input

=over

=item * C<info>, a hashref containing:

=over

=item - C<course_name>, the name of an existing course or C<course_id> the id of the course

=item - C<username>, the username of an existing user or C<user_id>, the id of the user

=back

=item * C<merged>, a boolean whether or not to return a merged user (include information
from the global user table)

=item * C<as_result_set>, a boolean if true returns as a C<DBIx::Class::ResultSet>

=back

=head3 notes:

=over
=item - If either information about the user or the course is missing, an exception will be thrown
=item - If the user isn't in the course, an exception will be thrown.
=back

=head3 output

An hashref of the user or merged user or a C<DBIx::Class::ResultSet>

=cut

sub getCourseUser ($self, %args) {
	my $course_user;

	if (defined($args{info}->{course_user_id})) {
		$course_user = $self->rs("CourseUser")->find({
			course_user_id => $args{info}->{course_user_id}
		});
	} else {
		my $course = $self->rs("Course")->getCourse(info => getCourseInfo($args{info}), as_result_set => 1);
		my $user   = $self->getGlobalUser(info => getUserInfo($args{info}), as_result_set => 1);
		$course_user = $self->rs("CourseUser")->find({ course_id => $course->course_id, user_id => $user->user_id });
		DB::Exception::UserNotInCourse->throw(
			message => "The user ${\$user->username} is not enrolled in the course ${\$course->course_name}")
			unless defined $course_user || $args{skip_throw};
	}

	return $course_user if $args{as_result_set};

	return $args{merged} ? _getMergedUser($course_user) : _getCourseUser($course_user);
}

=head1 addCourseUser

This adds a single user in a given course.

=head3 input

=over

=item * C<info>, a hashref containing:

=over

=item - C<course_name>, the name of an existing course or C<course_id> the id of the course

=item - C<username>, the username of an existing user or C<user_id>, the id of the user

=back

=item * C<params>, a hashref of all valid CourseUser parameters.  See C<DB::Schema::Result::CourseUser>
for details.

=item * C<merged>, a boolean whether or not to return a merged user (include information
from the global user table)

=item * C<as_result_set>, a boolean if true returns as a C<DB::Schema::ResultSet::CourseUser>

=back

=head3 notes:

=over
=item - If either information about the user or the course is missing, an exception will be thrown
=item - If the user is already in the course, an exception will be thrown.
=back

=head3 output

An hashref of the user or merged user or a C<DB::Schema::ResultSet::CourseUser>

=cut

sub addCourseUser ($self, %args) {
	my $course_user = $self->getCourseUser(info => $args{info}, as_result_set => 1, skip_throw => 1);
	DB::Exception::UserAlreadyInCourse->throw(
		message => "The user with " . $args{info}->{username} ? ("username: " . $args{info}->{username})
		: ("user_id: " . $args{info}->{user_id}) . " is already in the course with " . $args{params}->{course_name}
		? ("course name: " . $args{info}->{course_name})
		: ("course_id: " . $args{info}->{course_id}))
		if defined($course_user);

	my $params = clone($args{params});
	## remove the course_user_id if it is 0 (it's new)
	delete $params->{course_user_id} if defined($params->{course_user_id}) && $params->{course_user_id} == 0;

	for my $key (qw/ course_id course_name username user_id/) {
		delete $params->{$key};
	}

	# check for valid fields and parameters
	my $updated_user = $self->rs("CourseUser")->new($params);
	$updated_user->validParams('course_user_params');

	my $user   = $self->getGlobalUser(info => getUserInfo($args{info}), as_result_set => 1);
	my $course = $self->rs("Course")->getCourse(info => getCourseInfo($args{info}), as_result_set => 1);
	$course->add_to_users({ user_id => $user->user_id });

	my $user_to_return = $self->getCourseUser(
		info          => { user_id => $user->user_id, course_id => $course->course_id },
		as_result_set => 1
	);
	$user_to_return->update($params);

	return $user_to_return if $args{as_result_set};
	return $args{merged} ? _getMergedUser($user_to_return) : _getCourseUser($user_to_return);
}

=head2 updateCourseUser

This method updates the course user table

=head3 input

=over

=item * C<info>, a hashref containing:

=over

=item - C<course_name>, the name of an existing course or C<course_id> the id of the course

=item - C<username>, the username of an existing user or C<user_id>, the id of the user

=back

=item * C<params>, a hashref of all valid CourseUser parameters.  See C<DB::Schema::Result::CourseUser>
for details.

=item * C<merged>, a boolean whether or not to return a merged user (include information
from the global user table)

=item * C<as_result_set>, a boolean if true returns as a C<DB::Schema::ResultSet::CourseUser>

=back

=head3 notes:

=over
=item - If either information about the user or the course is missing, an exception will be thrown
=item - If the user is already in the course, an exception will be thrown.
=back

=head3 output

An hashref of the updated course user or merged user or a C<DB::Schema::ResultSet::CourseUser>

=cut

sub updateCourseUser ($self, %args) {
	my $course_user = $self->getCourseUser(info => $args{info}, as_result_set => 1);

	my $params_to_check = $self->rs("CourseUser")->new($args{params});
	$params_to_check->validParams("course_user_params");

	my $user_to_return = $course_user->update($args{params});

	return $user_to_return if $args{as_result_set};
	return return $args{merged} ? _getMergedUser($user_to_return) : _getCourseUser($user_to_return);
}

=head2 deleteCourseUser

This delete a single user from the course_user table.

=head3 input

=over

=item * C<info>, a hashref containing:

=over

=item - C<course_name>, the name of an existing course or C<course_id> the id of the course

=item - C<username>, the username of an existing user or C<user_id>, the id of the user

=back

=item * C<merged>, a boolean whether or not to return a merged user (include information
from the global user table)

=item * C<as_result_set>, a boolean if true returns as a C<DB::Schema::ResultSet::CourseUser>

=back

=head3 notes:

=over
=item - If either information about the user or the course is missing, an exception will be thrown
=item - If the user is already in the course, an exception will be thrown.
=back

=head3 output

An hashref of the deleted user or merged user or a C<DB::Schema::ResultSet::CourseUser>

=cut

sub deleteCourseUser ($self, %args) {
	my $course_user_to_delete = $self->getCourseUser(info => $args{info}, as_result_set => 1)->delete;

	return $course_user_to_delete if $args{as_result_set};
	return $args{merged} ? _getMergedUser($course_user_to_delete) : _getCourseUser($course_user_to_delete);

}

# This is a small subroutine to shorten access to the db.

sub rs {
	my ($self, $table) = @_;
	return $self->result_source->schema->resultset($table);
}

# This returns the course user fields

sub _getCourseUser {
	return { shift->get_inflated_columns };
}

# This returns the merged user fields (course user and global user)

sub _getMergedUser {
	my $course_user = shift;
	return removeLoginParams({ $course_user->get_inflated_columns, $course_user->users->get_inflated_columns });
}

1;
