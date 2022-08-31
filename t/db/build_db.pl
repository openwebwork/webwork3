#!/usr/bin/env perl

# This file fills a database with sample data from csv files.

use warnings;
use strict;
use feature 'say';

BEGIN {
	use File::Basename qw/dirname/;
	use Cwd qw/abs_path/;
	$main::ww3_dir = abs_path(dirname(__FILE__)) . '/../..';
}

use lib "$main::ww3_dir/lib";
use lib "$main::ww3_dir/t/lib";

use Carp;
use Clone qw/clone/;
use DateTime::Format::Strptime;
use YAML::XS qw/LoadFile/;
use Mojo::JSON qw/true false/;

use DB::Schema;
use DB::Utils qw/updatePermissions convertTimeDuration/;
use TestUtils qw/loadCSV/;

my $verbose = 1;

# Load the configuration for the database settings.
my $config_file = "$main::ww3_dir/conf/webwork3-test.yml";
$config_file = "$main::ww3_dir/conf/webwork3-test.dist.yml" unless (-e $config_file);

# the YAML true/false will be loaded a JSON booleans.
local $YAML::XS::Boolean = "JSON::PP";
my $config = LoadFile($config_file);

# Load the Permissions file
my $role_perm_file = "$main::ww3_dir/conf/permissions.yml";
$role_perm_file = "$main::ww3_dir/conf/permissions.dist.yml" unless -r $role_perm_file;

# Connect to the database.
my $schema = DB::Schema->connect(
	$config->{database_dsn},
	$config->{database_user},
	$config->{database_password},
	{ quote_names => 1 }
);

# $schema->storage->debug(1);  # print out the SQL commands.

say "restoring the database with dbi: $config->{database_dsn}" if $verbose;

# Create the database based on the schema.
$schema->deploy({ add_drop_table => 1 });

# The permissions need to be loaded into the DB before the rest of the script is run.
updatePermissions($config_file, $role_perm_file);

my $course_rs         = $schema->resultset('Course');
my $user_rs           = $schema->resultset('User');
my $course_user_rs    = $schema->resultset('CourseUser');
my $problem_set_rs    = $schema->resultset('ProblemSet');
my $problem_pool_rs   = $schema->resultset('ProblemPool');
my $set_problem_rs    = $schema->resultset('SetProblem');
my $user_set_rs       = $schema->resultset('UserSet');
my $role_rs           = $schema->resultset('Role');
my $global_setting_rs = $schema->resultset('GlobalSetting');

my $strp_date = DateTime::Format::Strptime->new(pattern => '%F', on_error => 'croak');

sub addCourses {
	say "adding courses" if $verbose;
	my @courses = loadCSV(
		"$main::ww3_dir/t/db/sample_data/courses.csv",
		{
			boolean_fields => ['visible']
		}
	);
	for my $course (@courses) {
		$course_rs->create($course);
	}
	return;
}
use Data::Dumper;

sub addSettings {
	say 'adding default settings' if $verbose;

	my $settings_file = "$main::ww3_dir/conf/course_settings.yml";
	$settings_file = "$main::ww3_dir/conf/course_settings.dist.yml" unless -r $settings_file;
	die "The default settings file: '$settings_file' does not exist or is not readable"
		unless -r $settings_file;
	my $course_settings = LoadFile($settings_file);
	for my $setting (@$course_settings) {

		# If the setting is a time_duration, store it as a number of seconds in the db.
		if ($setting->{type} eq 'time_duration') {
			$setting->{default_value} = convertTimeDuration($setting->{default_value});
		}
		$global_setting_rs->create($setting);
	}

	say 'adding course settings' if $verbose;
	my @course_settings = loadCSV("$main::ww3_dir/t/db/sample_data/course_settings.csv");
	for my $setting (@course_settings) {
		my $course = $course_rs->find({ course_name => $setting->{course_name} });
		die "the course: '$setting->{course_name}' does not exist in the db" unless $course;
		my $global_setting = $global_setting_rs->find({ setting_name => $setting->{setting_name} });
		die "the setting: '$setting->{setting_name}' does not exist in the db" unless $global_setting;

		# If the setting is a time_duration, store it as a number of seconds in the db.
		if ($global_setting->type eq 'time_duration') {
			$setting->{setting_value} = convertTimeDuration($setting->{setting_value});
		}

		$course->add_to_course_settings({
			course_id         => $course->course_id,
			global_setting_id => $global_setting->global_setting_id,
			value             => $setting->{setting_value}
		});
	}
	return;
}

sub addUsers {
	# Add some users
	say 'adding users' if $verbose;

	my @all_students = loadCSV(
		"$main::ww3_dir/t/db/sample_data/students.csv",
		{
			boolean_fields => ['is_admin']
		}
	);

	# Add an admin user
	my $admin = {
		username     => 'admin',
		email        => 'admin@google.com',
		first_name   => "Andrea",
		last_name    => "Administrator",
		is_admin     => true,
		login_params => { password => "admin" }
	};
	$user_rs->create($admin);

	for my $student (@all_students) {
		my $student_role = $role_rs->find({ role_name => 'student' });
		my $course       = $course_rs->find({ course_name => $student->{course_name} });
		my $stud_info    = {};
		for my $key (qw/username first_name last_name email student_id/) {
			$stud_info->{$key} = $student->{$key};
		}
		$stud_info->{login_params} = { password => $student->{username} };
		$course->add_to_users($stud_info, { role_id => $student_role->role_id });

		my $user   = $user_rs->find({ username => $student->{username} });
		my $params = {
			user_id   => $user->user_id,
			course_id => $course->course_id,
		};

		# Look up the role of the user
		my $role = $role_rs->find({ role_name => $student->{role} });
		die "The user with username $student->{username} has role $student->{role} which does not exist\n"
			. 'Either reassign the role or ensure that bin/update_perms.pl has been run.'
			unless defined $role;

		my $course_user = $course_user_rs->find($params);
		for my $key (qw/section recitation params/) {
			$params->{$key} = $student->{$key};
		}
		$params->{role_id}            = $role->role_id;
		$params->{course_user_params} = $params->{params} // {};
		delete $params->{params};
		my $u = $course_user->update($params);
	}
	return;
}

sub addSets {
	# Add some problem sets
	say 'adding problem sets' if $verbose;

	my @hw_sets = loadCSV(
		"$main::ww3_dir/t/db/sample_data/hw_sets.csv",
		{
			boolean_fields       => ['set_visible'],
			param_boolean_fields => [ 'enable_reduced_scoring', 'hide_hint' ]
		}
	);

	for my $set (@hw_sets) {
		my $course = $course_rs->find({ course_name => $set->{course_name} });
		if (!defined($course)) {
			croak 'The course ' . $set->{course_name} . ' does not exist';
		}

		delete $set->{course_name};
		$course->add_to_problem_sets($set);
	}

	# Add quizzes
	say 'adding quizzes' if $verbose;

	my @quizzes = loadCSV(
		"$main::ww3_dir/t/db/sample_data/quizzes.csv",
		{
			boolean_fields           => ['set_visible'],
			param_boolean_fields     => ['timed'],
			param_non_neg_int_fields => ['quiz_duration']
		}
	);
	for my $quiz (@quizzes) {
		my $course = $course_rs->search({ course_name => $quiz->{course_name} })->single;
		if (!defined($course)) {
			croak 'The course ' . $quiz->{course_name} . ' does not exist';
		}

		$quiz->{type} = 2;
		delete $quiz->{course_name};

		$course->add_to_problem_sets($quiz);
	}

	say 'adding review sets' if $verbose;

	my @review_sets = loadCSV(
		"$main::ww3_dir/t/db/sample_data/review_sets.csv",
		{
			boolean_fields       => ['set_visible'],
			param_boolean_fields => ['can_retake']
		}
	);
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
	# Add some problems
	say "adding problems" if $verbose;
	my @problems = loadCSV(
		"$main::ww3_dir/t/db/sample_data/problems.csv",
		{
			non_neg_float_fields       => ['status'],
			non_neg_int_fields         => [ 'seed', 'problem_number' ],
			param_non_neg_int_fields   => ['library_id'],
			param_non_neg_float_fields => ['weight']
		}
	);
	for my $prob (@problems) {
		# Check if the course_name/set_name exists
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

		my $problem_set = $problem_set_rs->search({ set_id => $set->set_id })->single;

		$problem_set->add_to_problems($prob);
	}
	return;
}

sub addUserSets {
	# Add some users to problem sets
	say "adding user sets" if $verbose;
	my @user_sets = loadCSV(
		"$main::ww3_dir/t/db/sample_data/user_sets.csv",
		{
			boolean_fields       => ['set_visible'],
			param_boolean_fields => [ 'enable_reduced_scoring', 'hide_hint' ]
		}
	);
	for my $user_set (@user_sets) {
		# Check if the course_name/set_name/user_name exists
		my $course         = $course_rs->find({ course_name => $user_set->{course_name} });
		my $user_in_course = $course->users->find({ username => $user_set->{username} });
		my $course_user    = $course_user_rs->find({
			user_id   => $user_in_course->user_id,
			course_id => $course->course_id
		});
		# say 'adding the user set for ' . $user_set->{username} . ' in ' . $user_set->{course_name};
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
	say 'adding problem pools' if $verbose;
	my @problem_pools = my @problem_pools_from_file =
		loadCSV("$main::ww3_dir/t/db/sample_data/pool_problems.csv", { non_neg_int_fields => ['library_id'] });

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
	my @user_problems = loadCSV(
		"$main::ww3_dir/t/db/sample_data/user_problems.csv",
		{
			non_neg_float_fields       => ['status'],
			non_neg_int_fields         => [ 'seed', 'problem_number' ],
			param_non_neg_int_fields   => ['library_id'],
			param_non_neg_float_fields => ['weight']
		}
	);
	for my $user_problem (@user_problems) {
		my $user_set = $user_set_rs->find(
			{
				'users.username'       => $user_problem->{username},
				'courses.course_name'  => $user_problem->{course_name},
				'problem_set.set_name' => $user_problem->{set_name}
			},
			{
				join => [ { problem_set => 'courses' }, { course_users => 'users' } ]
			}
		);
		my $problem = $set_problem_rs->find(
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
			set_problem_id  => $problem->set_problem_id,
			seed            => $user_problem->{seed},
			problem_version => 1,
			status          => 0 + $user_problem->{status}
		});
	}
	return;
}

addCourses;
addSettings;
addUsers;
addSets;
addProblems;
addUserSets;
addProblemPools;
addUserProblems;

1;
