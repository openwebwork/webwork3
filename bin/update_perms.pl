#!/usr/bin/env perl

=head1 NAME

update_perms.pl - Load the roles and permissions in conf/permissions.yml into the database

=head1 SYNOPSIS

update_perms.p [options]

 Options:
   -h|--help    Show full help

=head1 DESCRIPTION

All of the roles and permissions for webwork3 is defined in conf/permissions.yml (or it's
default file permissions.dist.yml).  This script checks for consistancy of that file and
then loads the roles and permissions into the database.

=cut

use warnings;
use strict;
use feature 'say';

BEGIN {
	use File::Basename qw/dirname/;
	use Cwd qw/abs_path/;
	$main::webwork3_dir = dirname(dirname(abs_path(__FILE__)));
}

use lib "$main::webwork3_dir/lib";

use Getopt::Long qw(:config bundling);
use Pod::Usage;
use YAML::XS qw/LoadFile/;
use DBI;
use DB::Schema;
use Try::Tiny;

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
# if it doesn't exist, load the default one:
$role_perm_file = "$main::webwork3_dir/conf/permissions.dist.yml" unless -r $role_perm_file;

# load any YAML true/false as booleans, not string true/false.
local $YAML::XS::Boolean = "JSON::PP";
my $role_perm = LoadFile($role_perm_file);

print "Rebuilding all role an permissions in database\n";

# clear out the tables role, db_perm, ui_perm
$schema->resultset('Role')->delete_all;
$schema->resultset('DBPermission')->delete_all;
$schema->resultset('UIPermission')->delete_all;

# add the roles to the database

my @roles = map { { role_name => $_ }; } @{ $role_perm->{roles} };
$schema->resultset('Role')->populate(\@roles);

# add the database permissions
for my $category (keys %{ $role_perm->{db_permissions} }) {
	for my $action (keys %{ $role_perm->{db_permissions}->{$category} }) {
		my $row = { category => $category, action => $action };
		$row->{admin_required} = $role_perm->{db_permissions}->{$category}->{$action}->{admin_required}
			if $role_perm->{db_permissions}->{$category}->{$action}->{admin_required};

		my $allowed_roles = $role_perm->{db_permissions}->{$category}->{$action}->{allowed_roles} // [];

		# check that the allowed roles is '*" or that the role exist.
		if ($allowed_roles && !(scalar(@$allowed_roles) == 1 && $allowed_roles->[0] eq '*')) {
			for my $role (@$allowed_roles) {
				my $role_in_db = $schema->resultset('Role')->find({ role_name => $role });
				die "The role '$role' does not exist." unless defined $role_in_db;
			}
		}
		$row->{allowed_roles} = $allowed_roles;

		$schema->resultset('DBPermission')->create($row);
	}
}

# add the UI permissions

for my $route (keys %{ $role_perm->{ui_permissions} }) {
	my $allowed_roles  = $role_perm->{ui_permissions}->{$route}->{allowed_roles} // [];
	my $admin_required = $role_perm->{ui_permissions}->{$route}->{admin_required};

	# check that the allowed roles exist.
	for my $role (@$allowed_roles) {
		next if $role eq '*';
		my $role_in_db = $schema->resultset('Role')->find({ role_name => $role });
		die "The role '$role' does not exist." unless defined $role_in_db;
	}

	$schema->resultset('UIPermission')->create({
		route          => $route,
		allowed_roles  => $allowed_roles,
		admin_required => $admin_required
	});
}

1;
