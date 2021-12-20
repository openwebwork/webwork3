#!/usr/bin/env perl
#
# This tests the basic database CRUD functions of user sets and merged set
#
use warnings;
use strict;

BEGIN {
	use File::Basename qw/dirname/;
	use Cwd qw/abs_path/;
	$main::ww3_dir = abs_path(dirname(__FILE__)) . '/../..';
}

use lib "$main::ww3_dir/lib";

use feature "say";
use Text::CSV qw/csv/;

use Test::More;
use Clone qw/clone/;
use Test::Exception;
use List::MoreUtils qw/firstval/;
use Try::Tiny;
use YAML::XS qw/LoadFile/;

use DB::Schema;
use DB::TestUtils qw/loadCSV removeIDs loadSchema/;

## load the configuration files and then the database

my $config_file = "$main::ww3_dir/conf/ww3-dev.yml";
die "The file $config_file does not exist.  Did you make a copy of it from ww3-dev.dist.yml ?"
	unless (-e $config_file);

my $config = LoadFile($config_file);

my $schema =
	DB::Schema->connect($config->{database_dsn}, $config->{database_user}, $config->{database_password});

# $schema->storage->debug(1);  # print out the SQL commands.

my $user_set_rs    = $schema->resultset("UserSet");
my $course_rs      = $schema->resultset("Course");
my $course_user_rs = $schema->resultset("CourseUser");
my $course         = $course_rs->find({ course_id => 1 });

# delete all user sets from the db for user otto, frink in the Precalc course
# and one set for ralph in the Arithmetic course
my @usersets_that_may_exist = $user_set_rs->search(
		{
			-or => [
				-and => [
					'courses.course_name' => 'Precalculus',
					-or => [
						'users.username' => 'otto',
						'users.username' => 'frink',
					]
				],
				-and => [
					'courses.course_name' => 'Arithmetic',
					'users.username' => 'ralph',
					'problem_sets.set_name' => 'HW #2'
				]
			]
		},
		{
			join => [
				{ problem_sets => 'courses' },
				{ course_users => 'users' }
			]
		}
	);

for my $u (@usersets_that_may_exist) {
	$u->delete;
}

# load info from CSV files

my @hw_sets = loadCSV("$main::ww3_dir/t/db/sample_data/hw_sets.csv");
for my $hw_set (@hw_sets) {
	$hw_set->{set_type}    = "HW";
	$hw_set->{set_version} = 1 unless defined($hw_set->{set_version});
}

my @quizzes = loadCSV("$main::ww3_dir/t/db/sample_data/quizzes.csv");
for my $set (@quizzes) {
	$set->{set_type}    = "QUIZ";
	$set->{set_version} = 1 unless defined($set->{set_version});
}

my @review_sets = loadCSV("$main::ww3_dir/t/db/sample_data/review_sets.csv");
for my $set (@review_sets) {
	$set->{set_type}    = "REVIEW";
	$set->{set_version} = 1 unless defined($set->{set_version});
}

my @all_problem_sets = (@hw_sets,@quizzes,@review_sets);

my @all_user_sets = loadCSV("$main::ww3_dir/t/db/sample_data/user_sets.csv");


for my $set (@all_user_sets) {
	$set->{set_version} = 1 unless defined($set->{set_version});
	# find the problem set type
	my $s = firstval {
		$_->{course_name} eq $set->{course_name} && $_->{set_name} eq $set->{set_name}
	} @all_problem_sets;
	$set->{set_type} = $s->{set_type};
}

my @merged_user_sets = @{clone(\@all_user_sets)};

# merge all the user sets with problem sets

for my $user_set (@merged_user_sets) {
	my $set = firstval {
		$_->{course_name} eq $user_set->{course_name} && $_->{set_name} eq $user_set->{set_name}
	}
	@all_problem_sets;

	# override problem set dates with userset dates if exist
	my $dates = clone($set->{set_dates});
	for my $d (keys %{$user_set->{set_dates}}) {
		$dates->{$d} = $user_set->{set_dates}->{$d};
	}

	# override problem set params with user set params if exist.
	my $params = clone($set->{set_params});
	for my $key (keys %{ $user_set->{set_params} }) {
		$params->{$key} = $user_set->{set_params}->{$key};
	}


	$user_set->{set_params}  = $params;
	$user_set->{set_dates}   = $dates;
	$user_set->{set_version} = 1 unless defined($user_set->{set_version});
	$user_set->{set_type}    = $set->{set_type} unless defined($user_set->{set_type});
	$user_set->{set_visible} = $set->{set_visible} unless defined($user_set->{set_visible});
}

## get all users sets for all courses

my @all_user_sets_from_db = $user_set_rs->getAllUserSets();

for my $set (@all_user_sets_from_db) {
	removeIDs($set);
	for my $key (keys %{$set}) {
		delete $set->{$key} unless defined $set->{$key};
	}
}

is_deeply(\@all_user_sets_from_db, \@all_user_sets, "getAllUserSets: get all merged sets for all courses");

my @merged_sets_from_db = $user_set_rs->getAllUserSets(merged=>1);

for my $merged_set (@merged_sets_from_db) {
	removeIDs($merged_set);
}

is_deeply(\@merged_sets_from_db, \@merged_user_sets, "getAllUserSets: get all merged sets for a user in a course");

## get all user set for a given user in a course

my @user_sets_for_one_user = grep { $_->{course_name} eq 'Precalculus' && $_->{username} eq 'homer' } @all_user_sets;

my @user_sets_from_db = $user_set_rs->getUserSets(user_set_info => {
	course_name => $course->course_name,
	username    => "homer"
});

for my $user_set (@user_sets_from_db) {
	removeIDs($user_set);
	delete $user_set->{set_visible} unless defined($user_set->{set_visible});
}

is_deeply(\@user_sets_from_db,\@user_sets_for_one_user, 'getUserSets: get all user sets for one user');


## get all merged set for a given user in a course

my @merged_sets_for_one_user = grep {
	$_->{course_name} eq 'Precalculus' && $_->{username} eq 'homer'
} @merged_user_sets;


@merged_sets_from_db = $user_set_rs->getUserSets(user_set_info => {
	course_name => $course->course_name,
	username    => "homer"
}, merged=>1);

for my $merged_set (@merged_sets_from_db) {
	removeIDs($merged_set);
}

is_deeply(\@merged_sets_from_db,\@merged_sets_for_one_user, 'getUserSets: get all merged sets for one user');

## get all user sets for a given set in a course

my @user_sets_for_one_set = grep {
	$_->{course_name} eq 'Precalculus' && $_->{set_name} eq 'HW #1'
} @all_user_sets;

@user_sets_from_db = $user_set_rs
	->getUserSets(user_set_info => { course_name => "Precalculus", set_name => "HW #1" });


for my $user_set (@user_sets_from_db) {
	removeIDs($user_set);
	delete $user_set->{set_visible} unless defined($user_set->{set_visible});
}

is_deeply(\@user_sets_from_db, \@user_sets_for_one_set, "getUserSets: get all user sets for a set in a course");

# get all merged user sets for a given set in a course

my @merged_sets_for_one_set = grep {
	$_->{course_name} eq 'Precalculus' && $_->{set_name} eq 'HW #1'
} @merged_user_sets;

@merged_sets_from_db = $user_set_rs->getUserSets(
	user_set_info => { course_name => "Precalculus", set_name => "HW #1" },
	merged => 1
);

for my $user_set (@merged_sets_from_db) {
	removeIDs($user_set);
}

is_deeply(\@merged_sets_from_db, \@merged_sets_for_one_set, "getUserSets: get all merged sets for a set in a course");


## try to get a user set from a non-existing course

throws_ok {
	$user_set_rs->getUserSets(user_set_info => { course_name => "non_existent_course", username => "homer" });
}
"DB::Exception::CourseNotFound", "getUserSets: attempt to get user sets from a nonexistent course";

## try to get a user set from a non-existing course

throws_ok {
	$user_set_rs->getUserSets(user_set_info => { course_name => "Precalculus", username => "non_existent_user" });
}
"DB::Exception::UserNotInCourse", "getUserSets: attempt to get user sets from a nonexistent user";

## try to get a user set from a user not in the course

throws_ok {
	$user_set_rs->getUserSets(user_set_info => { course_name => "non_existent_course", username => "bart" });
}
"DB::Exception::CourseNotFound", "getUserSets: attempt to get user sets from user not in the course";

## get a single UserSet

my $info = {
	username    => "homer",
	course_name => "Precalculus",
	set_name    => "HW #1"
};
my $user_set = $user_set_rs->getUserSet(user_set_info => $info);

my $user_set_from_csv = clone firstval {
	$_->{course_name} eq "Precalculus"
		&& $_->{username} eq $info->{username}
		&& $_->{set_name} eq $info->{set_name}
}
@all_user_sets;

removeIDs($user_set);
delete $user_set->{set_visible} unless defined($user_set->{set_visible});

is_deeply($user_set_from_csv, $user_set, "getUserSet: get a user set from a course");

## get a merged UserSet

my $merged_set_from_csv = clone firstval {
	$_->{course_name} eq "Precalculus"
		&& $_->{username} eq $info->{username}
		&& $_->{set_name} eq $info->{set_name}
}
@merged_user_sets;

my $merged_set = $user_set_rs->getUserSet(user_set_info => $info, merged => 1);
removeIDs($merged_set);

is_deeply($merged_set_from_csv, $merged_set, "getUserSet: get a merged set from a course");


## try to get a user set from a non-existent course

throws_ok {
	$user_set_rs->getUserSet(user_set_info => {
		course_name => "non_existent_course",
		username    => "homer",
		set_name    => "HW #1"
	});
}
"DB::Exception::CourseNotFound", "getUserSet: try to get a user set from a non-existent course";

## try to get a user set from a non-existent user

throws_ok {
	$user_set_rs->getUserSet(user_set_info => {
		course_name => "Precalculus",
		username    => "non_existent_user",
		set_name    => "HW #1"
	});
}
"DB::Exception::UserNotInCourse", "getUserSet: try to get a user set from a non-existent user";

## try to get a user set from a user not in the course

throws_ok {
	$user_set_rs->getUserSet(user_set_info => {
		course_name => "Precalculus",
		username    => "marge",
		set_name    => "HW #1"
	});
}
"DB::Exception::UserNotInCourse", "getUserSet: try to get a user set not in the course";

## try to get a user set from a non-existent set

throws_ok {
	$user_set_rs->getUserSet(user_set_info => {
		course_name => "Precalculus",
		username    => "homer",
		set_name    => "HW #999"
	});
}
"DB::Exception::SetNotInCourse", "getUserSet: try to get a user set from a non-existent set";

# add a user set

my $new_user_set_info = {
	username    => "otto",
	course_name => "Precalculus",
	set_name    => "HW #1"
};

my $new_user_set = $user_set_rs->addUserSet(user_set_info => $new_user_set_info);
removeIDs($new_user_set);

# set the other default parameters:
$new_user_set_info->{set_dates} = {};
$new_user_set_info->{set_params} = {};
$new_user_set_info->{set_version} = 1;
$new_user_set_info->{set_type} = 'HW';

is_deeply($new_user_set, $new_user_set_info, "addUserSet: add a new user set");

my $hw_set1 = clone firstval {
	$_->{course_name} eq "Precalculus" &&
	$_->{set_name} eq "HW #1"
} @hw_sets;

$hw_set1->{username} = "frink";


my $new_merged_set = $user_set_rs->addUserSet(user_set_info => {
	course_name => "Precalculus",
	set_name => "HW #1",
	username => "frink"
}, merged => 1);
removeIDs($new_merged_set);

is_deeply($new_merged_set, $hw_set1,
	"addUserSet: add a new user set and check that it is merged correctly");


# add a user set with a empty set of dates

my $new_user_params2 = {
	username    => "ralph",
	course_name => "Arithmetic",
	set_name    => "HW #2"
};

my $new_user_set2 = $user_set_rs->addUserSet(
	user_set_info => $new_user_params2,
	user_set_params => {set_dates => {}}
);



# try to add a user set to a course that doesn't exist

throws_ok {
	$user_set_rs->addUserSet(user_set_info => {
		username    => "otto",
		course_name => "non existent course",
		set_name    => "HW #1"
	});
}
"DB::Exception::CourseNotFound", "addUserSet: try to add a user set to a non-existent course";

# try to add a user set for a set that does not exist in a course

throws_ok {
	$user_set_rs->addUserSet(user_set_info => {
		username    => "otto",
		course_name => "Precalculus",
		set_name    => "HW #99"
	});
}
"DB::Exception::SetNotInCourse", "addUserSet: try to add a user set to a non-existent set";

# try to add a user set for a user that is not in a course

throws_ok {
	$user_set_rs->addUserSet(user_set_info => {
		username    => "ralph",
		course_name => "Precalculus",
		set_name    => "HW #1"
	});
}
"DB::Exception::UserNotInCourse", "addUserSet: try to add a user set for a user who is not in the course";

# try to add a user set with bad fields

throws_ok {
	$user_set_rs->addUserSet( user_set_info =>
		{
			username    => "otto",
			course_name => "Precalculus",
			set_name    => "HW #2"
		},
		user_set_params => {
			bad_field => 1
		}
	);
}
"DBIx::Class::Exception", "addUserSet: try to add a user set with a bad field";

# try to add a user_set that already exists

throws_ok {
	$user_set_rs->addUserSet(user_set_info => {
		username    => "otto",
		course_name => "Precalculus",
		set_name    => "HW #1"
	});
}
"DB::Exception::UserSetExists", "addUserSet: try to add a user set that already exists";

## add a user set with valid params

my $otto_set_info2 = {
		username    => "otto",
		course_name => "Precalculus",
		set_name    => "HW #2"
	};

my $otto_set_info3 = {
		username    => "otto",
		course_name => "Precalculus",
		set_name    => "HW #3"
	};

my $otto_set_info4 = {
		username    => "otto",
		course_name => "Precalculus",
		set_name    => "HW #4"
	};


my $user_set2 = $user_set_rs->addUserSet(user_set_info => $otto_set_info2,
	user_set_params => {
		set_params => {
			description => "This is the description for HW #2"
		}
	}
);
removeIDs($user_set2);

my $set_params2 = clone($otto_set_info2);
# set the other default parameters:
$set_params2->{set_dates} = {};
$set_params2->{set_params} = {
			description => "This is the description for HW #2"
		};
$set_params2->{set_version} = 1;
$set_params2->{set_type} = 'HW';

is_deeply($user_set2, $set_params2, "addUserSet: add a new user set with params");

## try to add a user set with a bad field in the set_params

throws_ok {
	$user_set_rs->addUserSet(user_set_info => $otto_set_info3,
		user_set_params => {
			set_params => {
				bad_field => 12
			}
		}
	);
}
"DB::Exception::UndefinedParameter", "addUserSet: try to add a new user set with an undefined parameter";


## add a user set with a new date

my $set_dates3 = {
			open   => 1,
			reduced_scoring => 800,
			due    => 900,
			answer => 1000
		};

my $user_set3 = $user_set_rs->addUserSet(
	user_set_info => $otto_set_info3,
	user_set_params => { set_dates => $set_dates3 }
);
removeIDs($user_set3);

my $set_params3 = clone($otto_set_info3);
$set_params3->{set_params} = {};
$set_params3->{set_dates} = $set_dates3;
$set_params3->{set_version} = 1;
$set_params3->{set_type} = 'HW';

is_deeply($user_set3, $set_params3, "addUserSet: add a new user set with dates");



## try to add a bad date

throws_ok {
	$user_set_rs->addUserSet(user_set_info => $otto_set_info4,
		user_set_params => {
			set_dates => {
				open   => 100,
				due    => 9,
				answer => 1000
			}
		}
	);
}
"DB::Exception::ImproperDateOrder", "addUserSet: dates are out of order";

throws_ok {
	$user_set_rs->addUserSet(user_set_info => $otto_set_info4,
		user_set_params => {
			set_dates => {
				open   => 100,
				due    => 900,
				answer => 800
			}
		}
	);
}
"DB::Exception::ImproperDateOrder", "addUserSet: dates are out of order";

## test that dates are merged correctly.

# first remove the sets added for user otto:

my @otto_user_sets = $user_set_rs->search(
		{
			'courses.course_name' => 'Precalculus',
			'users.username' => 'otto',
		},
		{
			join => [
				{ problem_sets => 'courses' },
				{ course_users => 'users' }
			]
		}
	);

for my $u (@otto_user_sets) {
	$u->delete;
}

## add a new user set and test that it is merged correctly

my $merged_set1 = clone firstval {
	$_->{course_name} eq $otto_set_info2->{course_name} &&
	$_->{set_name} eq $otto_set_info2->{set_name}
} @all_problem_sets;

$merged_set1->{username} = $otto_set_info2->{username};

my $new_dates = {
		due    => $merged_set->{set_dates}->{answer} + 1000,
		answer => $merged_set->{set_dates}->{answer} + 2000
	};

$merged_set1->{set_dates}->{due} = $new_dates->{due};
$merged_set1->{set_dates}->{answer} = $new_dates->{answer};

my $user_set_to_merge = $user_set_rs->addUserSet(user_set_info => $otto_set_info2,
		user_set_params => {
			set_dates => $new_dates
		},
		merged => 1
	);
removeIDs($user_set_to_merge);

is_deeply($merged_set1,$user_set_to_merge,'addUserSet: adding a user set with dates to check merging');

## check that adding a user set that are out of order with the problem sets throws an error

throws_ok {
	$user_set_rs->addUserSet(user_set_info => $otto_set_info3,
		user_set_params => {
			set_dates => {
				due => 1609595640, # this is after the problem set answer date.
			}
		},
		merged => 1
	);
}
"DB::Exception::ImproperDateOrder", "addUserSet: user set is out of order with respect to problem set";



## Update User Set

# get the user set for $otto_set_info2;

my $otto_set2 = $user_set_rs->getUserSet(user_set_info => $otto_set_info2);
removeIDs($otto_set2);

# update the dates

my $updated_dates = {
	due    => $otto_set2->{set_dates}->{due} + 100,
	answer => $otto_set2->{set_dates}->{due} + 1000
};

$otto_set2->{set_dates}->{due}    = $updated_dates->{due};
$otto_set2->{set_dates}->{answer} = $updated_dates->{answer};

my $updated_user_set = $user_set_rs->updateUserSet(user_set_info => $otto_set_info2,
	user_set_params => {
		set_dates => $updated_dates
	}
);
removeIDs($updated_user_set);

is_deeply($updated_user_set, $otto_set2, "updateUserSet: update the dates");

# update the params

my $updated_user_set2 = $user_set_rs->updateUserSet(user_set_info => $otto_set_info2,
	user_set_params => {
		set_params => {
			hide_hint => 1,
		}
	}
);

removeIDs($updated_user_set2);
$otto_set2->{set_params}->{hide_hint} = 1;

is_deeply($updated_user_set2, $otto_set2, "updateUserSet: update the params");

# try updating an invalid field

my $updated_user_set3 = $user_set_rs->updateUserSet(user_set_info => $otto_set_info2,
	user_set_params => {
		set_version => 2
	}
);
$otto_set2->{set_version} = 2;
removeIDs($updated_user_set3);
is_deeply($otto_set2, $updated_user_set3, "updateUserSet: update the set version");

# try updating an invalid field

throws_ok {
	$user_set_rs->updateUserSet(user_set_info => $otto_set_info2,
		user_set_params => {
			set_params => {
				not_a_valid_param => "bad"
			}
		}
	);
}
"DB::Exception::UndefinedParameter", "updateUserSet: try setting a parameter that is not allowed to be updated";

# try updating an invalid date

throws_ok {
	$user_set_rs->updateUserSet(user_set_info => $otto_set_info2,
		user_set_params => {
			set_dates => { open => 1, closed => 2 }
		}
	);
}
"DB::Exception::InvalidDateField", "updateUserSet: try to update an invalid date field";

# out of order dates

throws_ok {
	$user_set_rs->updateUserSet(user_set_info => $otto_set_info2,
		user_set_params => {
			set_dates => { open => 100, due => 2, answer => 200 }
		}
	);
}
"DB::Exception::ImproperDateOrder", "updateUserSet: try to update with out of order dates";

# update a user_set that doesn't exist;

throws_ok {
	$user_set_rs->updateUserSet(user_set_info => $otto_set_info3,
		user_set_params => {
			set_params => {
				hide_hint => 1
			}
		}
	);
}
"DB::Exception::UserSetNotInCourse", "updateUserSet: try to update a user set not the in the course";

# delete a user set

my $deleted_user_set = $user_set_rs->deleteUserSet(user_set_info => $otto_set_info2);
removeIDs($deleted_user_set);

is_deeply($deleted_user_set, $otto_set2, "deleteUserSet: successfully delete a user set");

# delete a user_set that doesn't exist;

throws_ok {
	$user_set_rs->deleteUserSet(user_set_info => $otto_set_info3);
}
"DB::Exception::UserSetNotInCourse", "deleteUserSet: try to delete a user set not the in the course";

done_testing;
