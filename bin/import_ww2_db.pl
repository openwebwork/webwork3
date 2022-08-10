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
   -x|--course_rebuild      Rebuild the database for the given course. This will
                           drop all rows in all columns associated with the given
                           course.
   -r|-rebuild_db          Completely rebuild the database.  This removes all courses.
   -c|--course             Name of the course to import
   -d|--database-dsn       The database-dsn string for webwork2.
   -u|--database-user      The database user for webwork2
   -p|--database-password  The password for the user on webwork2

=head1 DESCRIPTION

Import a course from webwork2 database to webwork3 format.

=cut

use strict;
use warnings;
use feature 'signatures';
no warnings qw(experimental::signatures);

use feature 'say';
use Getopt::Long qw(:config bundling);
use Pod::Usage;
use Try::Tiny;
use DBI;
use YAML::XS qw/LoadFile/;

BEGIN {
	use File::Basename qw/dirname/;
	use Cwd qw/abs_path/;
	$main::ww3_dir = abs_path(dirname(__FILE__)) . '/..';
}

use lib "$main::ww3_dir/lib";

use DB::Schema;
use DB::Schema::Result::CourseUser;

my $verbose        = 0;
my $rebuild_db     = 0;
my $rebuild_course = 0;
my $course_name    = '';
my $db_dsn         = '';
my $db_user        = '';
my $db_pass        = '';
GetOptions(
	'r|rebuild_db+'         => \$rebuild_db,
	'x|course_rebuild+'     => \$rebuild_course,
	'c|course=s'            => \$course_name,
	'v|verbose+'            => \$verbose,
	'd|database-dsn=s'      => \$db_dsn,
	'u|database-user=s'     => \$db_user,
	'p|database-password=s' => \$db_pass
) || pod2usage();

# Load the webwork3 configuration file.

my $config_file = "$main::ww3_dir/conf/webwork3.yml";
$config_file = "$main::ww3_dir/conf/webwork3.yml.dist" unless -e $config_file;

my $config = LoadFile($config_file);

die 'The webwork2 database must be passed in.'              unless $db_dsn;
die 'The webwork2 user must be passed in.'                  unless $db_user;
die 'The webwork2 password must be passed in.'              unless $db_pass;
die 'The webwork2 course to be imported must be passed in.' unless $course_name;

if ($verbose) {
	say "Rebuilding the database for course $course_name" if $rebuild_course;
	say "Using the webwork2 database: $db_dsn";
	say "with user $db_user";
	say "The webwork3 database: $config->{database_dsn}";
	say "with user $config->{database_user}";
}

my $dbh = DBI->connect($db_dsn, $db_user, $db_pass, { RaiseError => 1, AutoCommit => 0 });

my $schema = DB::Schema->connect(
	$config->{database_dsn},
	$config->{database_user},
	$config->{database_password},
	{ quote_names => 1 }
);

my $course_rs       = $schema->resultset('Course');
my $user_rs         = $schema->resultset('User');
my $problem_set_rs  = $schema->resultset('ProblemSet');
my $problem_rs      = $schema->resultset('Problem');
my $user_set_rs     = $schema->resultset('UserSet');
my $user_problem_rs = $schema->resultset('UserProblem');
my $attempts_rs     = $schema->resultset('Attempt');

# Create the database based on the schema
$schema->deploy({ add_drop_table => 1 }) if $rebuild_db;

my %PERMISSIONS = (
	0  => 'student',
	10 => 'instructor',
	20 => 'admin'
);

rebuildCourse() if $rebuild_course;

addCourse();
addUsers();
addProblemSets();
addProblems();
addUserSets();
addUserProblems();
addPastAnswers();

my $db_tables = {};

sub rebuildCourse ($=) {
	say "rebuilding the database for course $course_name";
	# Check if the course exists in the database.
	my $course;
	try {
		$course = $course_rs->getCourse(info => { course_name => $course_name });
	} catch {
	};

	return unless $course;

	removeAttempts();
	removeUserProblems();
	removeUserSets();
	removeUsers();
	removeProblems();
	removeProblemSets();
	removeCourse();
	return;
}

sub addCourse ($=) {
	say "adding course: $course_name" if $verbose;
	$course_rs->addCourse(params => { course_name => $course_name });
	return;
}

sub removeCourse ($=) {
	say 'in removeCourse';
	$course_rs->deleteCourse(info => { course_name => $course_name });
	say "deleting the course $course_name" if $verbose;
	return;
}

# Add/Remove Users

sub addUsers ($=) {
	my $user_table = $course_name . '_user';
	my $perm_table = $course_name . '_permission';

	my $sth = $dbh->prepare("SELECT * FROM `$user_table`");
	$sth->execute();
	my $ref  = $sth->fetchall_arrayref({});
	my @keys = keys %{ $ref->[0] };

	my @user_fields =
		grep { $_ ne 'login_params' && $_ ne 'user_id' && $_ ne 'email' } $user_rs->result_source->columns;
	my @course_user_param_fields = keys %$DB::Schema::Result::CourseUser::VALID_PARAMS;
	my @course_user_fields =
		grep { $_ !~ /\_id$/x && $_ ne 'course_user_params' } $schema->resultset('CourseUser')->result_source->columns;

	for my $r (@$ref) {
		# skip admin users to the course
		next if $r->{user_id} eq 'admin';

		# skip any proctors
		next if $r->{user_id} =~ /\w[\w\d\_]+:\w[\w\d\_]/;

		my $user_params = {
			username => $r->{user_id},
			email    => $r->{email_address}
		};
		foreach my $key (@user_fields) {
			$user_params->{$key} = $r->{$key} if defined($r->{$key});
		}

		my $user = $user_rs->find({ username => $user_params->{username} });
		$user_rs->addGlobalUser(params => $user_params) unless $user;
		say "Adding user with username $r->{user_id}" if $verbose && !defined($user);
		my $course_user = {
			username           => $r->{user_id},
			course_user_params => {}
		};
		for my $key (@course_user_fields) {
			$course_user->{$key} = $r->{$key} if defined($r->{$key});
		}
		foreach my $key (@course_user_param_fields) {
			$course_user->{course_user_params}->{$key} = $r->{$key} if defined($r->{$key});
		}
		my $user_id = $r->{user_id};
		my $sth2    = $dbh->prepare("SELECT * FROM `$perm_table` WHERE user_id = '$user_id';");
		$sth2->execute();
		my $perm = $sth2->fetchrow_hashref();
		$course_user->{role} = $PERMISSIONS{ $perm->{permission} };

		$user_rs->addCourseUser(
			info   => { course_name => $course_name, username => $course_user->{username} },
			params => $course_user
		);
	}
	return;
}

sub removeUsers ($=) {
	my @course_users = $user_rs->getCourseUsers(info => { course_name => $course_name });
	for my $course_user (@course_users) {
		my @user_courses = $course_rs->getUserCourses(info => { user_id => $course_user->{user_id} });
		# if each user is only in one course, delete the global user
		if (scalar(@user_courses) == 1) {
			my $global_user = $user_rs->deleteGlobalUser(info => { user_id => $course_user->{user_id} });

			say "deleting the global user with username: $global_user->{username}" if $verbose;
		} else {
			$user_rs->deleteUser(info => { course_name => $course_name, user_id => $course_user->{user_id} });
			say "From course $course_name, deleting user $course_user->{username}" if $verbose;
		}
	}
	return;
}

# Add/Remove Problem Sets

sub addProblemSets ($=) {

	my $set_table = $course_name . '_set';
	my $sth       = $dbh->prepare("SELECT * FROM `$set_table`");
	$sth->execute();
	my $ref = $sth->fetchall_arrayref({});

	for my $r (@$ref) {
		my $set_params = {
			set_name    => $r->{set_id},
			set_dates   => {},
			set_params  => {},
			set_visible => $r->{visible} // 0
		};

		if ($r->{assignment_type} eq 'default') {
			$set_params->{set_type} = 'HW';
			for my $key (qw/set_header hardcopy_header hide_hint enable_reduced_scoring/) {
				$set_params->{set_params}->{$key} = $r->{$key} if defined($r->{$key});
			}
			for my $key (qw/open due answer/) {
				$set_params->{set_dates}->{$key} = $r->{ $key . '_date' } // 0;
			}
			$set_params->{set_dates}->{reduced_scoring} = $r->{reduced_scoring_date} // $r->{due_date};

		} elsif ($r->{assignment_type} eq 'gateway' || $r->{assignment_type} eq 'proctored_gateway') {
			$set_params->{set_type} = 'QUIZ';
			for my $key (
				qw/set_header hardcopy_header problem_randorder problems_per_page
				hide_score hide_score_by_problem hide_work time_limit_cap restrict_ip relax_restrict_ip/
				)
			{
				$set_params->{set_params}->{$key} = $r->{$key} if defined($r->{$key});
			}
			$set_params->{set_params}->{quiz_duration} = $r->{time_interval} // 0;
			for my $key (qw/open due answer/) {
				$set_params->{set_dates}->{$key} = $r->{ $key . '_date' } // 0;
			}
		} elsif ($r->{assignment_type} eq 'jitar') {
			$set_params->{set_type} = 'HW';
			for my $key (qw/set_header hardcopy_header hide_hint enable_reduced_scoring/) {
				$set_params->{set_params}->{$key} = $r->{$key} if defined($r->{$key});
			}
			for my $key (qw/open due answer/) {
				$set_params->{set_dates}->{$key} = $r->{ $key . '_date' } // 0;
			}
			$set_params->{set_dates}->{reduced_scoring} = $r->{reduced_scoring_date} // $r->{due_date};
		}
		say "Adding set with name: $set_params->{set_name}" if $verbose;
		$problem_set_rs->addProblemSet(
			params => {
				course_name => $course_name,
				%$set_params
			}
		);

	}
	return;
}

sub removeProblemSets ($=) {
	my @problem_sets = $problem_set_rs->getProblemSets(info => { course_name => $course_name });
	for my $problem_set (@problem_sets) {
		$problem_set_rs->deleteProblemSet(info => { course_name => $course_name, set_id => $problem_set->{set_id} });
		say "deleting problem set: $problem_set->{set_name}" if $verbose;
	}
	return;
}

## Add/Remove UserSets

sub addUserSets ($=) {
	my $user_set_table = $course_name . '_set_user';
	my @problem_sets   = $problem_set_rs->getProblemSets(info => { course_name => $course_name });
	for my $set (@problem_sets) {
		say "Adding user sets for set $set->{set_name}" if $verbose;
		my $sth = $dbh->prepare("SELECT * FROM `$user_set_table` WHERE set_id = '$set->{set_name}'");
		$sth->execute();
		my $ref = $sth->fetchall_arrayref({});

		for my $r (@$ref) {
			next if $r->{user_id} eq 'admin';
			my $set_params = {
				set_dates   => {},
				set_params  => {},
				set_visible => $r->{visible},
			};

			if ($set->{set_type} eq 'HW') {
				# $set_params->{set_name}    = $r->{set_id};
				$set_params->{set_version} = 1;
				for my $key (qw/set_header hardcopy_header hide_hint enable_reduced_scoring/) {
					$set_params->{set_params}->{$key} = $r->{$key} if defined($r->{$key});
				}
				for my $key (qw/open due answer reduced_scoring/) {
					$set_params->{set_dates}->{$key} = $r->{ $key . '_date' } if defined $r->{ $key . '_date' };
				}
			} elsif ($set->{set_type} eq 'QUIZ') {
				# Only add user sets that have a version.
				if ($r->{set_id} =~ /^([\w\d]*),v(\d)$/) {
					$set_params->{set_name}    = $1;
					$set_params->{set_version} = $2;
				}
				for my $key (qw/set_header hardcopy_header hide_hint/) {
					$set_params->{set_params}->{$key} = $r->{$key} if defined($r->{$key});
				}
				for my $key (qw/open due answer/) {
					$set_params->{set_dates}->{$key} = $r->{ $key . '_date' } if defined $r->{ $key . '_date' };
				}
			} elsif ($set->{set_type} eq 'JITAR') {
				$set_params->{set_name}    = $r->{set_id};
				$set_params->{set_version} = 1;
				for my $key (qw/set_header hardcopy_header hide_hint enable_reduced_scoring/) {
					$set_params->{set_params}->{$key} = $r->{$key} if defined($r->{$key});
				}
				for my $key (qw/open due answer reduced_scoring/) {
					$set_params->{set_dates}->{$key} = $r->{ $key . '_date' } if defined $r->{ $key . '_date' };
				}
			}

			$user_set_rs->addUserSet(
				params => {
					course_name => $course_name,
					set_id      => $set->{set_id},
					username    => $r->{user_id},
					%$set_params
				}
			);
		}
	}
	return;
}

sub removeUserSets ($=) {
	my @problem_sets = $problem_set_rs->getProblemSets(info => { course_name => $course_name });
	for my $set (@problem_sets) {
		my @user_sets = $user_set_rs->getUserSets(
			info => {
				course_name => $course_name,
				set_id      => $set->{set_id}
			},
			as_result_set => 1
		);
		for my $user_set (@user_sets) {
			say 'Removing set ' . $set->{set_name} . ' for user ' . $user_set->course_users->users->username
				if $verbose;
			$user_set->delete;
		}
	}
	return;
}

## Add/Remove Problems

sub removeProblems ($=) {
	my @problems = $problem_rs->getProblems(info => { course_name => $course_name }, as_result_set => 1);
	for my $problem (@problems) {
		say 'Removing problem ' . $problem->problem_number . ' from ' . $problem->problem_set->set_name if $verbose;
		$problem->delete;
	}
	return;
}

sub addProblems ($=) {
	my $problem_table = $course_name . '_problem';
	my $sth           = $dbh->prepare("SELECT * FROM `$problem_table`");
	$sth->execute();
	my $ref = $sth->fetchall_arrayref({});
	for my $r (@$ref) {
		my $problem_params = { file_path => $r->{source_file} };
		for my $key (qw/value max_attempts/) {
			$problem_params->{$key} = $r->{$key} if $r->{$key};
		}

		my $problem_set = $problem_set_rs->getProblemSet(
			info          => { course_name => $course_name, set_name => $r->{set_id} },
			as_result_set => 1
		);

		$problem_set->add_to_problems({
			problem_number => $r->{problem_id},
			problem_params => $problem_params
		});
	}
	return;
}

# Add/Remove user problems

sub removeUserProblems ($=) {
	my @user_problems = $user_problem_rs->getUserProblems(
		info          => { course_name => $course_name },
		as_result_set => 1
	);
	for my $problem (@user_problems) {
		say 'Removing problem '
			. $problem->problems->problem_number
			. ' from '
			. $problem->user_sets->problem_set->set_name
			if $verbose;
		$problem->delete;
	}

	return;
}

sub addUserProblems ($=) {
	my $problem_user_table = $course_name . '_problem_user';
	my $sth                = $dbh->prepare("SELECT * FROM `$problem_user_table`");
	$sth->execute();
	my $ref = $sth->fetchall_arrayref({});

	say 'adding User Problems';
	my @user_problem_param_fields = keys %{ DB::Schema::Result::UserProblem::valid_params() };

	for my $r (@$ref) {
		# Skip any user problems from 'admin'.
		next if $r->{user_id} eq 'admin';
		my $course_user = $user_rs->getCourseUser(
			info          => { course_name => $course_name, username => $r->{user_id} },
			as_result_set => 1
		);

		my $params = {};
		my ($set_name, $problem_version);

		# If there is a quiz, need to parse the set_id differently
		if ($r->{set_id} =~ /^([\w\d]*),v(\d+)$/) {
			$set_name        = $1;
			$problem_version = $2;
			# say "$set_name $problem_version $r->{user_id}";

		} else {
			$set_name        = $r->{set_id};
			$problem_version = 1;
			my $problem_set = $problem_set_rs->getProblemSet(
				info => {
					course_name => $course_name,
					set_name    => $r->{set_id}
				},
				as_result_set => 1
			);
			# Skip a quiz that doesn't have a version number.
			next if $problem_set->set_type eq 'QUIZ';
		}

		for my $key (@user_problem_param_fields) {
			$params->{$key} = $r->{$key} if defined $r->{$key};
		}

		if ($params->{last_answer}) {
			$params->{last_answer} = join(';', split(/\s+/, $params->{last_answer}));
		}
		# say "Adding UserProblem for $r->{user_id} in set $set_name" if $verbose;
		$user_problem_rs->addUserProblem(
			params => {
				course_name     => $course_name,
				set_name        => $set_name,
				problem_number  => $r->{problem_id},
				username        => $r->{user_id},
				problem_version => $problem_version // 1,
				seed            => $r->{problemSeed},
				status          => $r->{status},
				problem_version => $problem_version,
				problem_params  => $params
			}
		);
	}
	return;
}

# Add and remove past_answer/attempts data

sub removeAttempts ($=) {
	my $all_attempts = $attempts_rs->search();
	$all_attempts->delete_all;
	return;
}

sub addPastAnswers ($=) {
	say 'adding Past Answers' if $verbose;
	my $past_answer_table = $course_name . '_past_answer';
	my $sth               = $dbh->prepare("SELECT * FROM `$past_answer_table`");
	$sth->execute();
	my $ref = $sth->fetchall_arrayref({});

	my $n = 0;
	my ($set_name, $problem_version);

	for my $r (@$ref) {
		my @answers  = $r->{answer_string} ? split(/\t/, $r->{answer_string}) : ();
		my @scores   = $r->{scores}        ? split(//,   $r->{scores})        : ();
		my @comments = $r->{comments}      ? split(/\t/, $r->{comments})      : ();
		if ($r->{set_id} =~ /^([\w\d]*),v(\d+)$/) {
			$set_name        = $1;
			$problem_version = $2;
		}
		say "Adding an attempt for user $r->{user_id} problem number $r->{problem_id}"
			. " and problem version $problem_version in set $set_name"
			if $verbose;
		my $att = $attempts_rs->addAttempt(
			params => {
				course_name     => $course_name,
				set_name        => $set_name,
				problem_number  => $r->{problem_id},
				problem_version => $problem_version,
				username        => $r->{user_id},
				comments        => \@comments,
				scores          => \@scores,
				answers         => \@answers
			}
		);
	}
	return;
}

1;
