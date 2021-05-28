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
use Data::Dump qw/dd/;

use DB::Utils qw/checkUserInfo/;


=pod
=head1 getUsers

This gets a list of all users or users stored in the database in the <code>users</codes> table. 

=head3 input 

none 

=head3 output 

An array of courses as a <code>DBIx::Class::ResultSet::Course</code> object.  

=cut

sub getUsers {
	my ($self,$as_result_set) = @_;
	return $self->search({}) if $as_result_set; 
	return  $self->search({},{result_class => 'DBIx::Class::ResultClass::HashRefInflator'});
} 

=pod
=head1 getUser

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

sub getUser {
	my ($self,$user_info,$as_result_set) = @_;
	checkUserInfo($user_info);
	my $user = $self->find($user_info);
	croak "user with info: $user_info not in the database" unless defined($user);
	return $user if $as_result_set; 
	return {$user->get_columns} if defined($user);
	
}


=pod
=head1 addUser

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

sub addUser {
	my ($self,$params, $as_result_set) = @_;
	croak "The parameters must include login" unless defined $params->{login};
	my $new_user = $self->create($params);
	return {$new_user->get_columns};
}

=pod
=head1 deleteUser

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

sub deleteUser {
	my ($self,$user_info, $as_result_set) = @_;
	checkUserInfo($user_info);
	my $user_to_delete = $self->find($user_info);
	croak "The user with info $user_info does not exist" unless defined($user_to_delete);
  my $deleted_user = $user_to_delete->delete; 
	return $deleted_user if $as_result_set; 
	return {$deleted_user->get_columns};
}

=pod
=head1 updateUser

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

sub updateUser {
	my ($self,$user_info,$user_params,$as_result_set) = @_;
	my $user = $self->getUser($user_info,1); 
	croak "A user with login info $user_info does not exist" unless defined($user);
	my $updated_user = $user->update($user_params); 

	return $updated_user if $as_result_set;
	return {$user->get_columns};  
}

1;