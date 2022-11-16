#!/usr/bin/env perl

=head1 NAME

update_perms.pl - Load the roles and permissions in conf/permissions.yml into the database

=head1 SYNOPSIS

update_perms.p [options]

 Options:
   -h|--help    Show full help

=head1 DESCRIPTION

All of the roles and permissions for webwork3 are defined in conf/permissions.yml (or it's
default file permissions.dist.yml).  This script checks for consistancy of that file and
then loads the roles and permissions into the database.

=cut

use warnings;
use strict;

require Exporter;
use base qw(Exporter);
our @EXPORT_OK = qw/updatePermissions/;

BEGIN {
	use File::Basename qw/dirname/;
	use Cwd qw/abs_path/;
	$main::webwork3_dir = dirname(dirname(abs_path(__FILE__)));
}

use lib "$main::webwork3_dir/lib";

use Getopt::Long qw(:config bundling);
use Pod::Usage;
use DB::Schema;
use YAML::XS qw/LoadFile/;

use DB::Utils qw/updatePermissions/;

my $showHelp;
GetOptions('h|help' => \$showHelp);
pod2usage({ -verbose => 2, -exitval => 0 }) if $showHelp;

# Load the configuration to obtain the database settings.
my $ww3_conf = "$main::webwork3_dir/conf/webwork3.yml";
$ww3_conf = "$main::webwork3_dir/conf/webwork3.dist.yml" unless -r $ww3_conf;
my $config = LoadFile($ww3_conf);

# Connect to the database.
my $schema = DB::Schema->connect(
	$config->{database_dsn},
	$config->{database_user},
	$config->{database_password},
	{ quote_names => 1 }
);

my $role_perm_file = "$main::webwork3_dir/conf/permissions.yml";
$role_perm_file = "$main::webwork3_dir/conf/permissions.dist.yml" unless -r $role_perm_file;

updatePermissions($schema, $role_perm_file);

1;
