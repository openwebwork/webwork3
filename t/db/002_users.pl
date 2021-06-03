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
use Carp;

use DB::Schema; 
use DB::CSVUtils qw/loadCSV/;

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
# $schema->storage->debug(1);  # print out the SQL commands.

my $users_rs = $schema->resultset("User"); 

## get a list of users from the CSV file
my @students = loadCSV("sample_data/students.csv");

for my $student (@students){
	for my $key (qw/course_name params roles/){
		delete $student->{$key};
	}
}

my@all_students = orderUsers(@students);

## get a list of all users

my @users_from_db = $users_rs->getAllGlobalUsers; 
for my $user (@users_from_db){
	delete $user->{user_id};
}
@users_from_db = sort {$a->{login} cmp $b->{login}} @users_from_db;

is_deeply(\@all_students,\@users_from_db,"getUsers: all users");

## get one user that exists

my $user = $users_rs->getGlobalUser({login => $all_students[0]->{login}});
delete $user->{user_id}; 
is_deeply($all_students[0],$user,"getUser: by login");

$user = $users_rs->getGlobalUser({user_id => 2});
delete $user->{user_id}; 
is_deeply($students[1],$user,"getUser: by user_id");


## get one user that does not exist

dies_ok {
	$user = $users_rs->getGlobalUser({user_id => -9});
} "getUser: undefined user_id";
dies_ok {
	$user = $users_rs->getGlobalUser({login => "non_existent_user"});
} "getUser: undefined login";

## add one user

$user = {
	login => "wiggam",
	last_name => "Wiggam",
	first_name => "Clancy",
	email => 'wiggam@springfieldpd.gov',
	student_id => ''
};

my $new_user = $users_rs->addGlobalUser($user); 
delete $new_user->{user_id};
is_deeply($user,$new_user,"addUser: adding a user");

## update a user

my $updated_user = { %$user };  # make a copy of $user;
$updated_user->{email} = 'spring.cop@gmail.com';
my $up_user_from_db = $users_rs->updateGlobalUser({login => $updated_user->{login}},$updated_user);
delete $up_user_from_db->{user_id};
is_deeply($updated_user,$up_user_from_db,"updateUser: updating a user");

## try to update a user without passing login info:

dies_ok {
	$users_rs->updateGlobalUser({login_name => "wiggam"},$updated_user);
} "updateUser: wrong user_info sent";

## try to update a user that doesn't exist:

dies_ok {
	$users_rs->updateGlobalUser({login => "non_existent_user"},$updated_user);
} "updateUser: update user for a non-existing login";
dies_ok {
	$users_rs->updateGlobalUser({user_id => -5},$updated_user);
} "updateUser: update user for a non-existing user_id";


## delete a user

my $user_to_delete = $users_rs->deleteGlobalUser({login => $user->{login}});
delete $user_to_delete->{user_id};
is_deeply($updated_user,$user_to_delete,"deleteUser: delete a user");

## delete a user that doesn't exist.  

dies_ok {
	$user = $users_rs->deleteGlobalUser({login => "undefined_login"});
} "deleteUser: trying to delete with undefined login";
dies_ok {
	$user = $users_rs->deleteGlobalUser({user_id => -3});
} "deleteUser: trying to delete with undefined user_id";

done_testing; 


