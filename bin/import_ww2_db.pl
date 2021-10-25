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
   -w|--webwork-root     Directory containing a git clone of webwork2.
                         If this option is not set, then the environment
                         variable $WEBWORK_ROOT will be used if it is set.
   -p|--pg-root          Directory containing  a git clone of pg.
                         If this option is not set, then the environment
                         variable $PG_ROOT will be used if it is set.
   -r|--rebuild_db       Rebuild the database for the given course. This will
	                       drop all rows in all columns associated with the given
												 course.
   -c|--course           Name of the course to import

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
use Data::Dump qw/dd/;
use Try::Tiny;
use DBI;

BEGIN {
	use File::Basename qw/dirname/;
	use Cwd qw/abs_path/;
	$main::bin_dir = abs_path(dirname(__FILE__));
	$main::lib_dir = dirname($main::bin_dir) . '/lib';
}

use lib "$main::lib_dir";

use DB::Schema;
use DB::Schema::Result::CourseUser;

my $verbose    = 0;
my $rebuild_db = 0;
GetOptions(
	'r|rebuild+' => \$rebuild_db,
	'c|course=s' => \$course_name,
	'v|verbose+' => \$verbose
) || pod2usage();

my $ww2_dsn = "DBI:mysql:database=webwork;host=localhost;port=3306";
my $dbh     = DBI->connect($ww2_dsn, "webworkWrite", "password", { RaiseError => 1, AutoCommit => 0 });

my $ww3_dsn = "DBI:mysql:database=webwork3;host=localhost;port=3306";
my $schema  = DB::Schema->connect($ww3_dsn, "webworkWrite", "password");

my $course_rs      = $schema->resultset('Course');
my $user_rs        = $schema->resultset('User');
my $problem_set_rs = $schema->resultset('ProblemSet');

# test if the database tables are created.
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

my $db_tables = {};

sub rebuild {
	# find the course users
	my @course_users = $user_rs->getUsers({ course_name => $course_name });

	## delete the users

	for my $course_user (@course_users) {
		my @user_courses = $course_rs->getUserCourses({ user_id => $course_user->{user_id} });
		# if each user is only in one course, delete the global user
		if (scalar(@user_courses) == 1) {
			$user_rs->deleteGlobalUser({ user_id => $course_user->{user_id} });
			say "deleting the global user with username: $course_user->{username}" if $verbose;
		} else {
			$user_rs->deleteUser({ course_name => $course_name, user_id => $course_user->{user_id} });
			say "From course $course_name, deleting user $course_user->{username}" if $verbose;
		}
	}

	## delete the problem sets

	my @problem_sets = $problem_set_rs->getProblemSets({ course_name => $course_name });
	for my $problem_set (@problem_sets) {
		$problem_set_rs->deleteProblemSet({ course_name => $course_name, set_id => $problem_set->{set_id} });
		say "deleting problem set: $problem_set->{set_name}" if $verbose;
	}

	# delete the course
	my $course = $course_rs->find({ course_name => $course_name });
	$course->delete                        if $course;
	say "deleting the course $course_name" if $verbose;
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
		my $user_params = {
			username => $r->{user_id},
			email    => $r->{email_address}
		};
		foreach my $key (@user_fields) {
			$user_params->{$key} = $r->{$key} if defined($r->{$key});
		}
		# dd $user_params;
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
		$user_rs->addUser({ course_name => $course_name }, $course_user);
	}
	return;
}

sub addProblemSets {
	my @hw_param_keys = keys %$DB::Schema::Result::ProblemSet::HWSet::VALID_PARAMS;
	my $set_table     = $course_name . "_set";
	my $sth           = $dbh->prepare("SELECT * FROM `$set_table`");
	$sth->execute();
	my $ref  = $sth->fetchall_arrayref({});
	my @keys = keys %{ $ref->[0] };
	# dd @keys;
	for my $r (@$ref) {
		my $set_params = {
			set_name => $r->{set_id},
			dates    => {},
			params   => {},
		};
		if ($r->{assignment_type} eq 'default') {    # it's a homework set
			for my $key (@hw_param_keys) {
				$set_params->{params}->{$key} = $r->{$key} if defined($r->{$key});
			}
			for my $key (@DB::Schema::Result::ProblemSet::HWSet::VALID_DATES) {
				$set_params->{dates}->{$key} = $r->{ $key . '_date' } if defined($r->{ $key . '_date' });
			}
		}

		$problem_set_rs->addProblemSet({ course_name => $course_name }, $set_params);
		say "Adding set with name: $set_params->{set_name}" if $verbose;
	}
	return;
}

1;
