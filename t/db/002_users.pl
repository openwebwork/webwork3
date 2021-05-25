# 
# This tests the basic database CRUD functions with courses. 
#
use warnings;
use strict;

use lib "../../lib";

use Text::CSV qw/csv/;
use Data::Dump qw/dd/;
use List::MoreUtils qw/uniq first_value/;
use Test::More; 
use Test::Exception;

use DB::Schema; 

## order users on login_name; 

sub orderUsers {
  my @array = @_; 
  my %temp_hash = map { $_->{login}, 0 } @_; 
  my @login_names = sort (keys %temp_hash); 
  my @users = ();
  for my $key (@login_names) {
    push(@users,first_value {$_->{login} eq $key} @array);
  }
  return @users; 
}

# load the database
my $db_file = "sample_db.sqlite";
my $schema = DB::Schema->connect("dbi:SQLite:$db_file");

my $users = $schema->resultset("User"); 

## get a list of users from the CSV file

my $students = csv (in => "students.csv", headers => "lc");
for my $student (@$students){
  for my $key (qw/recitation section comment roles course_name/){
    delete $student->{$key};
  }
}

my@all_students = orderUsers(@$students);


## get a list of all users

my @users_from_db = $users->getUsers; 
for my $user (@users_from_db){
  delete $user->{user_id};
}
@users_from_db = sort {$a->{login} cmp $b->{login}} @users_from_db;

is_deeply(\@all_students,\@users_from_db,"all users");

## get one user that exists

my $user = $users->getUser($all_students[0]->{login});
delete $user->{user_id}; 
is_deeply($all_students[0],$user,"get one user");

## get one user that does not exist

dies_ok {
  $user = $users->getUser("CSDxdif9");
} "undefined user";

## add one user

$user = {
  login => "wiggam",
  last_name => "Wiggam",
  first_name => "Clancy",
  email => 'wiggam@springfieldpd.gov',
  student_id => ''
};

my $new_user = $users->addUser($user); 
delete $new_user->{user_id};
is_deeply($user,$new_user,"adding a user");

## update a user

my $updated_user = { %$user };  # make a copy of $user;
$updated_user->{email} = 'spring.cop@gmail.com';
my $up_user_from_db = $users->updateUser($updated_user);
delete $up_user_from_db->{user_id};
is_deeply($updated_user,$up_user_from_db,"updating a user");

## try to update a user without passing login info:

dies_ok {
  $users->updateUser({login_name => "wiggam"});
} "dies without sending login";

## try to update a user that doesn't exist:

dies_ok {
  $users->updateUser({login => "CSDxdif9", student_id => "1234"});
} "update user for a non-existing user";


## delete a user

my $user_to_delete = $users->deleteUser($user->{login});
delete $user_to_delete->{user_id};
is_deeply($updated_user,$user_to_delete,"delete a user");

## delete a user that doesn't exist.  

dies_ok {
  $user = $users->deleteUser("CSDxdif9");
} "delete an undefined user";

done_testing; 


