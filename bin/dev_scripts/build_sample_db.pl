#!/usr/bin/env perl

# This file fills a database with sample data from JSON files.

use warnings;
use strict;
use feature 'say';

use Mojo::File qw/curfile/;
use YAML::XS qw/LoadFile/;

use lib curfile->dirname->dirname->sibling('lib')->to_string;
use lib curfile->dirname->dirname->sibling('t/lib')->to_string;

use DB::Schema;
use BuildDB qw/loadPermissions addCourses addUsers addSets addProblems addUserSets addProblemPools addUserProblems/;

my $ww3_dir = curfile->dirname->dirname->dirname;

# Load the configuration for the database settings.
my $config_file = $ww3_dir->child('conf', 'webwork3-dev.yml');
$config_file = $ww3_dir->child('conf/webwork3.yml')      unless -e $config_file;
$config_file = $ww3_dir->child('conf/webwork3.dist.yml') unless -e $config_file;
my $config = LoadFile($config_file);

# Connect to the database.
my $schema = DB::Schema->connect(
	$config->{database_dsn},
	$config->{database_user},
	$config->{database_password},
	{ quote_names => 1 }
);

say "restoring the database with dbi: $config->{database_dsn}";

# Create the database based on the schema.
$schema->deploy({ add_drop_table => 1 });

# The permissions need to be loaded into the database first.
say 'loading permissions';
loadPermissions($schema, $ww3_dir);

say 'adding courses';
addCourses($schema, $ww3_dir);

say 'adding users';
addUsers($schema, $ww3_dir);

say 'adding problem sets';
addSets($schema, $ww3_dir);

say 'adding problems';
addProblems($schema, $ww3_dir);

say 'adding user sets';
addUserSets($schema, $ww3_dir);

say 'adding problem pools';
addProblemPools($schema, $ww3_dir);

say 'adding user problems';
addUserProblems($schema, $ww3_dir);

1;
