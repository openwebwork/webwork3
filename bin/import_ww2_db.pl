#!/usr/bin/perl
################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2021 The WeBWorK Project, https://github.com/openwebwork
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of either: (a) the GNU General Public License as published by the
# Free Software Foundation; either version 2, or (at your option) any later
# version, or (b) the "Artistic License" which comes with this package.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See either the GNU General Public License or the
# Artistic License for more details.
################################################################################

=head1 NAME

import_ww2_db.pl - Import a course from webwork2 database to webwork3 format.

=head1 SYNOPSIS

import_ww2_db.pl [options]

 Options:
   -r|--rebuild_db         Rebuild the database for the given course. This will
                           drop all rows in all columns associated with the given
                           course.
   -c|--course             Name of the course to import
   -d|--database-dsn       The database-dsn string for webwork2.
   -u|--database-user      The database user for webwork2
   -p|--database-password  The password for the user on webwork2

Note that at least one of the options --webwork-root or --pg-root must be provided
(or there is nothing to do!).

=head1 DESCRIPTION

Import a course from webwork2 database to webwork3 format.

=cut

use strict;
use warnings;
use feature 'say';
use Getopt::Long qw(:config bundling);
use Pod::Usage;
use Try::Tiny;
use DBI;
use YAML::XS qw/LoadFile/;
use Data::Dumper;

BEGIN {
	use File::Basename qw/dirname/;
	use Cwd qw/abs_path/;
	$main::ww3_dir = abs_path(dirname(__FILE__)) . '/..';
}

use lib "$main::ww3_dir/lib";

use DB::Schema;
use DB::Schema::Result::CourseUser;

my $verbose    = 0;
my $rebuild_db = 0;
my $course_name = '';
my $db_dsn = '';
my $db_user = '';
my $db_pass = '';
GetOptions(
	'r|rebuild_db+'         => \$rebuild_db,
	'c|course=s'            => \$course_name,
	'v|verbose+'            => \$verbose,
	'd|database-dsn=s'      => \$db_dsn,
	'u|database-user=s'     => \$db_user,
	'p|database-password=s' => \$db_pass
) || pod2usage();


# Load the webwork3 configuration file:

my $config_file = "$main::ww3_dir/conf/webwork3.yml";
die "The file $config_file does not exist.  Did you make a copy of it from ww3-dev.dist.yml ?"
	unless (-e $config_file);

my $config = LoadFile($config_file);

use Data::Dumper;

if ($verbose) {
	say "Rebuilding the database for course $course_name";
	say "Using the webwork2 database: $db_dsn";
	say "with user $db_user";
	say "The webwork3 database: " . $config->{database_dsn};
	say "with user " . $config->{database_user};
}

my $dbh     = DBI->connect($db_dsn, $db_user, $db_pass, { RaiseError => 1, AutoCommit => 0 });

my $schema  = DB::Schema->connect($config->{database_dsn},
	$config->{database_user}, $config->{database_password});

my $course_rs      = $schema->resultset('Course');
my $user_rs        = $schema->resultset('User');
my $problem_set_rs = $schema->resultset('ProblemSet');
my $problem_rs     = $schema->resultset('Problem');

# test if the database tables are created.  If not have DBIx::Class create them.
try {
	$course_rs->getCourses();
} catch {
	$schema->deploy;
};

my %PERMISSIONS = (
	0  => "student",
	10 => "instructor",
	20 => "admin"
);

rebuild() if $rebuild_db;

addCourse();
addUsers();
addProblemSets();
addProblems();
#removeProblems();

my $db_tables = {};

sub rebuild {

	# check if the course exists in the database;
	my $course;
	try {
		$course = $course_rs->getCourse({ course_name => $course_name });
	} catch { };

	return unless $course;

	removeUsers();
	removeProblems();
	removeProblemSets();
	removeCourse();

	return;
}

sub buildTables {
	$db_tables = {};
	for my $name (qw/user key password past_answer/) {
		$db_tables->{$name} = $course_name . "_" . $name;
	}
	return;
}

sub addCourse {
	say "adding course: $course_name" if $verbose;
	$course_rs->addCourse({ course_name => $course_name });
	return;
}

sub removeCourse {
	my $course = $course_rs->find({ course_name => $course_name });
	$course->delete                        if $course;
	say "deleting the course $course_name" if $verbose;
}

sub addUsers {
	my $user_table = $course_name . "_user";
	my $perm_table = $course_name . "_permission";

	my $sth = $dbh->prepare("SELECT * FROM `$user_table`");
	$sth->execute();
	my $ref  = $sth->fetchall_arrayref({});
	my @keys = keys %{ $ref->[0] };

	my @user_fields =
		grep { $_ ne "login_params" && $_ ne "user_id" && $_ ne "email" } $user_rs->result_source->columns;
	my @course_user_param_fields = keys %$DB::Schema::Result::CourseUser::VALID_PARAMS;
	my @course_user_fields =
		grep { $_ !~ /\_id$/x && $_ ne "params" } $schema->resultset("CourseUser")->result_source->columns;

	for my $r (@$ref) {
		# skip admin users to the course
		next if $r->{user_id} eq 'admin';

		my $user_params = {
			username => $r->{user_id},
			email    => $r->{email_address}
		};
		foreach my $key (@user_fields) {
			$user_params->{$key} = $r->{$key} if defined($r->{$key});
		}


		my $user = $user_rs->find({ username => $user_params->{username} });
		$user_rs->addGlobalUser($user_params) unless $user;
		say "Adding user with username $r->{user_id}" if $verbose && !defined($user);
		my $course_user = {
			username => $r->{user_id},
			params   => {}
		};
		for my $key (@course_user_fields) {
			$course_user->{$key} = $r->{$key} if defined($r->{$key});
		}
		foreach my $key (@course_user_param_fields) {
			$course_user->{params}->{$key} = $r->{$key} if defined($r->{$key});
		}
		my $user_id = $r->{user_id};
		my $sth2    = $dbh->prepare("SELECT * FROM `$perm_table` WHERE user_id = '$user_id';");
		$sth2->execute();
		my $perm = $sth2->fetchrow_hashref();
		$course_user->{role} = $PERMISSIONS{ $perm->{permission} };

		$user_rs->addCourseUser({ course_name => $course_name, username => $course_user->{username} },
			$course_user);
	}
	return;
}

sub removeUsers {
	my @course_users = $user_rs->getCourseUsers({ course_name => $course_name });
	for my $course_user (@course_users) {
		my @user_courses = $course_rs->getUserCourses({ user_id => $course_user->{user_id} });
		# if each user is only in one course, delete the global user
		if (scalar(@user_courses) == 1) {
			my $global_user = $user_rs->deleteGlobalUser({ user_id => $course_user->{user_id} });

			say "deleting the global user with username: $global_user->{username}" if $verbose;
		} else {
			$user_rs->deleteUser({ course_name => $course_name, user_id => $course_user->{user_id} });
			say "From course $course_name, deleting user $course_user->{username}" if $verbose;
		}
	}
}

# Add/Remove Problem Sets

sub addProblemSets {

	my $set_table     = $course_name . "_set";
	my $sth           = $dbh->prepare("SELECT * FROM `$set_table`");
	$sth->execute();
	my $ref  = $sth->fetchall_arrayref({});
	my @keys = keys %{ $ref->[0] };
	# dd @keys;
	for my $r (@$ref) {
		my $set_params = {
			set_name => $r->{set_id},
			set_dates    => {},
			set_params   => {},
			set_visible  => $r->{visible} // 0
		};

		if ($r->{assignment_type} eq 'default') {    # it's a homework set
		  $set_params->{set_type} = 'HW';
			for my $key (qw/set_header hardcopy_header hide_hint enable_reduced_scoring/) {
				$set_params->{set_params}->{$key} = $r->{$key} if defined($r->{$key});
			}
			for my $key (qw/open due answer/) {
				$set_params->{set_dates}->{$key} = $r->{ $key . '_date' } // 0;
			}
			$set_params->{set_dates}->{reduced_scoring} = $r->{reduced_scoring_date} // $r->{due_date};

		} elsif ($r->{assignment_type} eq 'gateway') {
			$set_params->{set_type} = 'QUIZ';
			for my $key (qw/set_header hardcopy_header problem_randorder problems_per_page
				hide_score hide_score_by_problem hide_work time_limit_cap restrict_ip relax_restrict_ip/) {
				$set_params->{set_params}->{$key} = $r->{$key} if defined($r->{$key});
			}
			$set_params->{set_params}->{quiz_duration} = $r->{time_interval} // 0;
			for my $key (qw/open due answer/) {
				$set_params->{set_dates}->{$key} = $r->{ $key . '_date' } // 0;
			}
		} elsif ($r->{assignment_type} eq 'jitar') {
			## need to determine how to handle these problems.
			next;
		}

		$problem_set_rs->addProblemSet({ course_name => $course_name }, $set_params);
		say "Adding set with name: $set_params->{set_name}" if $verbose;
	}
	return;
}

sub removeProblemSets {
	my @problem_sets = $problem_set_rs->getProblemSets({ course_name => $course_name });
	for my $problem_set (@problem_sets) {
		$problem_set_rs->deleteProblemSet({ course_name => $course_name, set_id => $problem_set->{set_id} });
		say "deleting problem set: $problem_set->{set_name}" if $verbose;
	}
}

## Add/Remove Problems

sub removeProblems {
	my @problems = $problem_rs->getProblems({course_name => $course_name},1);
	for my $problem (@problems) {
		say "Removing problem " . $problem->problem_number . " from " . $problem->problem_set->set_name if $verbose;
		$problem->delete;
	}
}

sub addProblems {
	my $problem_table = $course_name . "_problem";
	my $sth           = $dbh->prepare("SELECT * FROM `$problem_table`");
	$sth->execute();
	my $ref  = $sth->fetchall_arrayref({});
	for my $r (@$ref) {
		my $problem_params = {
			file_path => $r->{source_file}
		};
		for my $key (qw/value max_attempts/) {
			$problem_params->{$key} = $r->{$key} if $r->{$key};
		}

		my $problem_set = $problem_set_rs->getProblemSet({course_name => $course_name, set_name => $r->{set_id}},1);
		$problem_set->add_to_problems({
			problem_number => $r->{problem_id},
			problem_params => $problem_params
		});
	}
}

1;
