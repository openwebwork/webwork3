#!/usr/bin/env perl

=head1 NAME

setup_db.pl - Create and setup the webwork3 database for production usage.

=head1 SYNOPSIS

setup_db.pl [options]

 Options:
   -h|--help    Show full help

=head1 DESCRIPTION

Create and setup the webwork3 database for production usage.

Set the values of C<database_dsn>, C<database_user>, and C<database_password> in
C<conf/webwork3.yml> before running this script.

Note that this script must be run as root to create the database and user for
mysql or mariadb.

At this time it is assumed that the database host is localhost, and this script
does not support alternate hosts or ports.

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
my $config = LoadFile("$main::webwork3_dir/conf/webwork3.yml");

my ($database_dbi, $database_type, $database_attr) = $config->{database_dsn} =~ m/([^:]*):([^:]*):([^:;]*).*/;

if ($database_type eq 'mysql') {
	pod2usage({
		-message  => 'Root access is required to create a mysql or mariadb databse.',
		-verbose  => 99,
		-sections => 'SYNOPSIS|DESCRIPTION',
		-exitval  => 1
	})
		if (getpwuid($<) ne 'root');

	my $database_name = $database_attr =~ s/dbname=//gr;

	try {
		# Connect to the database as the root user.
		my $dbh = DBI->connect("$database_dbi:$database_type:", '', '', { PrintError => 0, RaiseError => 1 });

		# List all databases, and if the database does not already exist, then create it.
		if (!grep { $_->[0] eq $database_name } @{ $dbh->selectall_arrayref('SHOW DATABASES') }) {
			say "Creating database '$database_name'.";
			$dbh->do("CREATE DATABASE $database_name");
		} else {
			say "Not Creating database '$database_name'.  Database already exists.";
		}

		# List all users, and if the user does not already exist, then create it.
		if (!grep { $_->[0] eq $config->{database_user} } @{ $dbh->selectall_arrayref('SELECT user FROM mysql.user') })
		{
			say "Creating user '$config->{database_user}'.";
			$dbh->do("CREATE USER '$config->{database_user}'\@'localhost' "
					. "IDENTIFIED BY '$config->{database_password}'");
		} else {
			say "Not creating user '$config->{database_user}'.  User already exists.";
		}

		# Grant the necessary permissions to the user.
		$dbh->do('GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, ALTER, DROP, LOCK TABLES '
				. "ON $database_name.* TO '$config->{database_user}'\@'localhost'");
	} catch {
		say "ERROR: There was an error communicating with mysql.";
		exit 1;
	}
} elsif ($database_type eq 'Pg') {
	pod2usage({
		-message  => 'You must be signed in as the postgres user to create a postgres user.',
		-verbose  => 99,
		-sections => 'SYNOPSIS|DESCRIPTION',
		-exitval  => 1
	})
		if (getpwuid($<) ne 'postgres');

	my $database_name = $database_attr =~ s/dbname=//gr;

	try {
		my $dbh = DBI->connect("DBI:Pg:dbname=postgres", 'postgres', '', { PrintError => 0, RaiseError => 1 });

		# List all databases, and if the database does not already exist, then create it.
		if (!grep { $_->[0] eq $database_name } @{ $dbh->selectall_arrayref('SELECT datname FROM pg_database') }) {
			say "Creating database '$database_name'.";
			$dbh->do(qq{CREATE DATABASE "$database_name"});
		} else {
			say "Not Creating database '$database_name'.  Database already exists.";
		}

		# List all users, and if the user does not already exist, then create it.
		if (!grep { $_->[0] eq $config->{database_user} } @{ $dbh->selectall_arrayref('SELECT usename FROM pg_user') })
		{
			say "Creating user '$config->{database_user}'.";
			$dbh->do(qq{CREATE USER "$config->{database_user}" WITH PASSWORD '$config->{database_password}'});
		} else {
			say "Not creating user '$config->{database_user}'.  User already exists.";
		}
	} catch {
		say "ERROR: There was an error communicating with postgres.";
		exit 1;
	}
}

# Connect to the database.
my $schema = DB::Schema->connect(
	$config->{database_dsn},
	$config->{database_user},
	$config->{database_password},
	{ quote_names => 1 }
);

# Deploy the database as specified by the webwork3 schema.
say "Setting up the database with dsn '$config->{database_dsn}'";
$schema->deploy({ add_drop_table => 1 });

1;
