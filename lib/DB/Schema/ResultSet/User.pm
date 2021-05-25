=pod
 
=head1 DESCRIPTION
 
This is the functionality of a User in WeBWorK.  This package is based on 
<code>DBIx::Class::ResultSet</code>.  The basics are a CRUD for users.  
 
=cut


package DB::Schema::ResultSet::User;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

use Try::Tiny; 
use Data::Dump qw/dd/;

=pod
=head1 getUsers

This gets a list of all users or users stored in the database in the <code>users</codes> table. 

=head3 input 

none 

=head3 output 

An array of courses as a <code>DBIx::Class::ResultSet::Course</code> object.  

=cut

sub getUsers {
	my ($self) = @_;
  return  $self->search({},{result_class => 'DBIx::Class::ResultClass::HashRefInflator'});
} 

=pod
=head1 getUser

Gets a single user from the <code>users</code> table. 

=head3 input 

<code>login_name</code>, a string

=head3 output 

The user as  <code>DBIx::Class::ResultSet::User</code> object or <code>undef</code> if no user exists. 

=cut

sub getUser {
	my ($self,$login_name) = @_;
	my $user = $self->find({login => $login_name});
  return {$user->get_columns} if defined($user);
  croak "user $login_name not in the database"; 
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

sub addUser {
	my ($self,$params) = @_;
  croak "The parameters must include login" unless defined $params->{login};
  my $new_user = $self->create($params);
  return {$new_user->get_columns};
}

=pod
=head1 deleteUser

This deletes a single user that is stored in the database in the <code>users</codes> table. 

=head3 input 

<code>login</code>, a string, the login name of the user to be deleted.  

=head3 output 

The deleted user as a <code>DBIx::Class::ResultSet::User</code> object.  

=cut


## TODO: delete everything related to the user from all tables. 

sub deleteUser {
	my ($self,$login_name) = @_;
	my $deleted_user = $self->find({login => $login_name})->delete;
  return {$deleted_user->get_columns};
}

=pod
=head1 updateUser

This updates a single user that is stored in the database in the <code>user</codes> table. 

=head3 input 


<code>params</code>, a hashref of the user parameters.   The following structure is expected:
=item * login (required)
=item * first_name
=item * last_name
=item * email
=item * student_id

=head3 output 

The updated course as a <code>DBIx::Class::ResultSet::Course</code> object.  

=cut

sub updateUser {
	my ($self,$params) = @_;
  croak "login must be defined" unless defined $params->{login};
  my $user_rs; 
  try {
    $user_rs = $self->find({login => $params->{login}} ); 
  } catch  {
    croak "A user with login " . $params->{login} . " does not exist";
  };
  my $user = $user_rs->update($params); ## may need to check that other params are valid.  
	return {$user->get_columns};  
}

1;