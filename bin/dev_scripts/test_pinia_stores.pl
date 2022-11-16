#!/usr/bin/env perl

=head1 NAME

test_pinia_stores.pl - Run the webwork3 client side pinia stores unit tests.

=head1 SYNOPSIS

test_pinia_stores.pl [options]

 Options:
   -p |--port=port_number    Use port_number for the server instance.
                             (Default: 3333)

   -ta|--test-all-dbs        Test with all supported database types, currently
                             sqlite, postgres, and mysql.  If this is not set
                             the tests will run once with sqlite.

   -h |--help                Show full help

=head1 DESCRIPTION

This script runs a Mojolicious server daemon that serves the webwork3 server api
app.  It then deploys the webwork3 database, and fills it with sample data from
JSON files.  Finally, it runs the jest pinia stores tests in a subprocess.

The port used by the server daemon defaults to port 3333.  That can be changed
with the -p option, or by setting the environment variable WW3_TEST_PORT to the
desired port.

By default the tests are run only once using an in memory sqlite database.
However if the -ta option is given or the environment variable WW3_TEST_ALL_DBS
is set to a truthy value, then the tests are run three times consecutively with
an in memory sqlite database, then with a postgres databaase, and then with a
mysql database.  The postgres and mysql database instances are temporary
instances created via the Test::PostgreSQL package and a modified local version
of the Test::mysqld package (TestMysqld located in t/lib).

=cut

use Mojo::Base;
use Mojo::File qw(curfile);
use Mojo::IOLoop::Subprocess;
use Mojo::Server::Daemon;
use Test::PostgreSQL;
use Getopt::Long qw(:config bundling_override);
use Pod::Usage;

use lib curfile->dirname->dirname->sibling('lib')->to_string;
use lib curfile->dirname->dirname->sibling('t/lib')->to_string;

use BuildDB qw/loadPermissions addCourses addUsers addSets addProblems addUserSets addProblemPools addUserProblems/;
use TestMysqld;

GetOptions('p|port=s' => \my $port, 'ta|test-all-dbs' => \my $test_all_dbs, 'h|help' => \my $show_help)
	or pod2usage({ -verbose => 1, -exitval => 1 });
pod2usage({ -verbose => 2, -exitval => 0, -noperldoc => 1 }) if $show_help;

$port         //= $ENV{WW3_TEST_PORT}    // '3333';
$test_all_dbs //= $ENV{WW3_TEST_ALL_DBS} // 0;

die qq{The node_modules directory was not detected or is not readable.  Have you run "npm install"?\n}
	unless -r curfile->dirname->dirname->sibling('node_modules');

for my $db_type ($test_all_dbs ? ('sqlite', 'postgres', 'mysql') : 'sqlite') {
	print "Testing pinia stores with database $db_type\n";

	my ($sqld, $dsn);

	# Load the database.
	if ($db_type eq 'postgres') {
		$sqld = eval { Test::PostgreSQL->new } or die "Unable to initialize psql instance\n";
		$dsn  = $sqld->dsn;
	} elsif ($db_type eq 'mysql') {
		$sqld = eval { TestMysqld->new(my_cnf => { 'skip-networking' => '' }) }
			or die $TestMysqld::errstr;
		$dsn = $sqld->dsn;
	} else {
		$dsn = 'dbi:SQLite:dbname=:memory:';
	}

	# Setup the webwork3 api app.
	my $app = Mojo::Server->new->build_app(
		'WeBWorK3' => {
			config => {
				config_override => 1,
				secrets         => ['1234'],
				database_dsn    => $dsn,
				cookie_secure   => 0,
				cookie_lifetime => 3600,
				$db_type eq 'postgres' ? (database_on_connect_do => 'SET client_min_messages=WARNING;') : ()
			}
		}
	);

	$app->log->path($app->home->child('logs', 'webwork3_test.log'));

	my $schema = $app->schema;

	# Deploy the database.
	$schema->deploy({ add_drop_table => 1 });

	# Load sample data used by the store tests.
	loadPermissions($schema, $app->home);
	addCourses($schema, $app->home);
	addUsers($schema, $app->home);
	addSets($schema, $app->home);
	addProblems($schema, $app->home);
	addUserSets($schema, $app->home);
	addProblemPools($schema, $app->home);
	addUserProblems($schema, $app->home);

	# Start the server.
	my $daemon = Mojo::Server::Daemon->new(app => $app, listen => ["http://[::]:$port"]);
	$daemon->start;

	Mojo::IOLoop->subprocess->run(
		sub {
			# Run the tests.
			system(
				'npx', 'jest', '--verbose', '--runInBand', '--testURL',
				"http://localhost:$port/webwork3/api",
				$app->home->child('tests/stores')
			);
		},
		sub {
			# This must be done here for postgres or exceptions are thrown after the test finishes in some cases
			# because the postgres daemon can stop before the Mojolicious app disconnects the schema from the
			# database.  It doesn't hurt for the others.
			$schema->storage->disconnect;

			Mojo::IOLoop->stop;
		}
	);

	Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
}
