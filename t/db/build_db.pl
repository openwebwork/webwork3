#!/usr/bin/env perl

#
# this file fills a database with sample data for testing.
#

use warnings;
use strict;

BEGIN {
	use File::Basename qw/dirname/;
	use Cwd qw/abs_path/;
	$main::ww3_dir = abs_path(dirname(__FILE__)) . '/../..';
}

use lib "$main::ww3_dir/lib";

use Text::CSV qw/csv/;
use Carp;
use feature "say";

use Clone qw/clone/;
use DateTime::Format::Strptime;
use YAML::XS qw/LoadFile/;

use DB::WithParams;
use DB::WithDates;

use DB::Schema;
use DB;
use DB::TestUtils qw/loadCSV/;

my $verbose = 1;

# load some configuration for the database:
my $config_file = "$main::ww3_dir/conf/ww3-dev.yml";
die "The file $config_file does not exist.  Did you make a copy of it from ww3-dev.dist.yml ?"
	unless (-e $config_file);

my $config = LoadFile($config_file);

# load the database
my $schema =
	DB::Schema->connect($config->{database_dsn}, $config->{database_user}, $config->{database_password});

# $schema->storage->debug(1);  # print out the SQL commands.

say "restoring the database with dbi: $config->{database_dsn}" if $verbose;

$schema->deploy({ add_drop_table => 1 });    ## create the database based on the schema

my $course_rs       = $schema->resultset('Course');
my $user_rs         = $schema->resultset('User');
my $course_user_rs  = $schema->resultset('CourseUser');
my $problem_set_rs  = $schema->resultset('ProblemSet');
my $problem_pool_rs = $schema->resultset('ProblemPool');
my $problem_rs      = $schema->resultset('Problem');
my $user_set_rs     = $schema->resultset('UserSet');

sub addCourses {
	say "adding courses" if $verbose;
	my @courses = loadCSV("$main::ww3_dir/t/db/sample_data/courses.csv");
	for my $course (@courses) {
		$course->{course_settings} = {};
		for my $key (keys %{ $course->{course_params} }) {
			my @fields = split(/:/, $key);
			$course->{course_settings}->{ $fields[0] } = { $fields[1] => $course->{course_params}->{$key} };
		}
		delete $course->{course_params};
		$course_rs->create($course);
	}
	return;
}

sub addUsers {
	# add some users
	say "adding users" if $verbose;

	my @all_students = loadCSV("$main::ww3_dir/t/db/sample_data/students.csv");

	# add an admin user
	my $admin = {
		username     => "admin",
		email        => 'admin@google.com',
		first_name   => "Andrea",
		last_name    => "Administrator",
		is_admin     => 1,
		login_params => { password => "admin" }
	};
	$user_rs->create($admin);

	for my $student (@all_students) {
		my $course    = $course_rs->find({ course_name => $student->{course_name} });
		my $stud_info = {};
		for my $key (qw/username first_name last_name email student_id/) {
			$stud_info->{$key} = $student->{$key};
		}
		$stud_info->{login_params} = { password => $student->{username} };
		$course->add_to_users($stud_info);

		my $user   = $user_rs->find({ username => $student->{username} });
		my $params = {
			user_id   => $user->user_id,
			course_id => $course->course_id,
		};

		my $course_user = $course_user_rs->find($params);
		for my $key (qw/section recitation params role/) {
			$params->{$key} = $student->{$key};
		}
		$params->{course_user_params} = $params->{params} // {};
		delete $params->{params};
		my $u = $course_user->update($params);
	}
	return;
}

my $strp = DateTime::Format::Strptime->new(pattern => '%FT%T', on_error => 'croak');

sub addSets {
	## add some problem sets
	say "adding problem sets" if $verbose;

	my @hw_sets = loadCSV("$main::ww3_dir/t/db/sample_data/hw_sets.csv");
	for my $set (@hw_sets) {
		my $course = $course_rs->find({ course_name => $set->{course_name} });
		if (!defined($course)) {
			croak "The course " . $set->{course_name} . " does not exist";
		}

		delete $set->{course_name};
		$course->add_to_problem_sets($set);
	}

	## add quizzes
	say "adding quizzes" if $verbose;

	my @quizzes = loadCSV("$main::ww3_dir/t/db/sample_data/quizzes.csv");
	for my $quiz (@quizzes) {
		my $course = $course_rs->search({ course_name => $quiz->{course_name} })->single;
		if (!defined($course)) {
			croak "The course " . $quiz->{course_name} . " does not exist";
		}

		$quiz->{type} = 2;
		delete $quiz->{course_name};
		$course->add_to_problem_sets($quiz);
	}

	say "adding review sets" if $verbose;

	my @review_sets = loadCSV("$main::ww3_dir/t/db/sample_data/review_sets.csv");
	for my $set (@review_sets) {
		my $course = $course_rs->find({ course_name => $set->{course_name} });
		croak "The course |$set->{course_name}| does not exist" unless defined($course);

		$set->{type} = 4;
		delete $set->{course_name};
		$course->add_to_problem_sets($set);
	}

	return;
}

sub addProblems {
	## add some problems
	say "adding problems" if $verbose;
	my @problems = loadCSV("$main::ww3_dir/t/db/sample_data/problems.csv");
	for my $prob (@problems) {
		# check if the course_name/set_name exists
		my $set = $problem_set_rs->find(
			{
				'me.set_name'         => $prob->{set_name},
				'courses.course_name' => $prob->{course_name}
			},
			{
				join => 'courses'
			}
		);
		croak "The course |$set->{course_name}| with set name |$set->{name}| is not defined" unless defined($set);
		delete $prob->{course_name};
		delete $prob->{set_name};
		delete $prob->{params};

		$prob->{problem_number} = int($prob->{problem_number});

		## the following isn't working.   Perhaps because it is the result of a join
		# $sets[0]->add_to_problems->($prob);
		my $problem_set = $problem_set_rs->search({ set_id => $set->set_id })->single;

		$problem_set->add_to_problems($prob);

	}
	return;
}

sub addUserSets {
	## add some users to problem sets
	say "adding user sets" if $verbose;
	my @user_sets = loadCSV("$main::ww3_dir/t/db/sample_data/user_sets.csv");
	for my $user_set (@user_sets) {
		# check if the course_name/set_name/user_name exists
		my $course         = $course_rs->find({ course_name => $user_set->{course_name} });
		my $user_in_course = $course->users->find({ username => $user_set->{username} });
		my $course_user    = $course_user_rs->find({
			user_id   => $user_in_course->user_id,
			course_id => $course->course_id
		});
		# say "adding the user set for " . $user_set->{username} . " in " . $user_set->{course_name};
		if (defined $course_user) {
			my $problem_set = $schema->resultset('ProblemSet')->find({
				course_id => $course->course_id,
				set_name  => $user_set->{set_name}
			});
			for my $key (qw/course_name set_name type username/) {
				delete $user_set->{$key};
			}
			$user_set->{course_user_id} = $course_user->course_user_id;
			$user_set->{set_id}         = $problem_set->set_id;
			$problem_set->add_to_user_sets($user_set);
		}
	}
	return;
}

sub addProblemPools {
	say "adding problem pools" if $verbose;
	my @problem_pools = loadCSV("$main::ww3_dir/t/db/sample_data/pool_problems.csv");

	for my $pool (@problem_pools) {
		my $course = $course_rs->find({ course_name => $pool->{course_name} });
		croak "The course |$pool->{course_name}| does not exist" unless defined($course);

		my $prob_pool =
			$problem_pool_rs->find_or_create({ course_id => $course->course_id, pool_name => $pool->{pool_name} });
		$prob_pool->add_to_pool_problems({ params => { library_id => $pool->{params}->{library_id} } });

	}
	return;
}

sub addUserProblems {
	say "adding user problems" if $verbose;
	my @user_problems = loadCSV("$main::ww3_dir/t/db/sample_data/user_problems.csv");
	for my $user_problem (@user_problems) {
		# print Dumper $user_problem;
		my $user_set = $user_set_rs->find(
			{
				'users.username'        => $user_problem->{username},
				'courses.course_name'   => $user_problem->{course_name},
				'problem_sets.set_name' => $user_problem->{set_name}
			},
			{
				join => [ { problem_sets => 'courses' }, { course_users => 'users' } ]
			}
		);
		my $problem = $problem_rs->find(
			{
				'courses.course_name'  => $user_problem->{course_name},
				'problem_set.set_name' => $user_problem->{set_name},
				'problem_number'       => $user_problem->{problem_number}
			},
			{
				join => { 'problem_set' => 'courses' }
			}
		);

		$user_set->add_to_user_problems({
			problem_id => $problem->problem_id,
			seed       => $user_problem->{seed},
			status     => 1
		});
	}
	return;
}

addCourses;
addUsers;
addSets;
addProblems;
addUserSets;
addProblemPools;
addUserProblems;

1;
