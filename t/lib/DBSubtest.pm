package DBSubtest;
use parent Exporter;

use Mojo::Base -signatures;
use Test2::Tools qw/plan skip_all/;
use Test2::Tools::AsyncSubtest;
use Test::PostgreSQL;

use DB::Schema;
use TestMysqld;

our @EXPORT_OK = qw/dbSubtest mojoDBSubtest/;

sub dbSubtest ($name, $code) {
	my @db_subtests;

	for my $db_type ($ENV{WW3_TEST_ALL_DBS} ? ('sqlite', 'postgres', 'mysql') : 'sqlite') {
		push(
			@db_subtests,
			fork_subtest "Test $name with database $db_type" => sub {
				my ($sqld, $schema);

				# Load the database.
				if ($db_type eq 'postgres') {
					$sqld = eval { Test::PostgreSQL->new }
						or plan(skip_all => 'Unable to initialize psql instance');
					$schema = DB::Schema->connect($sqld->dsn, undef, undef,
						{ quote_names => 1, on_connect_do => 'SET client_min_messages=WARNING;' });
				} elsif ($db_type eq 'mysql') {
					$sqld = eval { TestMysqld->new(my_cnf => { 'skip-networking' => '' }) }
						or plan(skip_all => $TestMysqld::errstr);
					$schema = DB::Schema->connect($sqld->dsn);
				} else {
					$schema = DB::Schema->connect('dbi:SQLite:dbname=:memory:');
				}

				# Deploy the database.
				$schema->deploy({ add_drop_table => 1 });

				# Execute the subtest.
				$code->($schema);
			}
		);
	}

	(shift @db_subtests)->finish while (@db_subtests);

	return;
}

sub mojoDBSubtest ($name, $code) {
	my @db_subtests;

	for my $db_type ($ENV{WW3_TEST_ALL_DBS} ? ('sqlite', 'postgres', 'mysql') : 'sqlite') {
		push(
			@db_subtests,
			fork_subtest "Test $name with database $db_type" => sub {
				my ($sqld, $dsn);

				# Load the database.
				if ($db_type eq 'postgres') {
					$sqld = eval { Test::PostgreSQL->new }
						or plan(skip_all => 'Unable to initialize psql instance');
					$dsn = $sqld->dsn;
				} elsif ($db_type eq 'mysql') {
					$sqld = eval { TestMysqld->new(my_cnf => { 'skip-networking' => '' }) }
						or plan(skip_all => $TestMysqld::errstr);
					$dsn = $sqld->dsn;
				} else {
					$dsn = 'dbi:SQLite:dbname=:memory:';
				}

				my $t = Test2::MojoX->new(
					WeBWorK3 => {
						secrets         => ['1234'],
						database_dsn    => $dsn,
						cookie_secure   => 0,
						cookie_lifetime => 3600,
						$db_type eq 'postgres' ? (database_on_connect_do => 'SET client_min_messages=WARNING;') : ()
					}
				);

				my $schema = $t->app->schema;

				# Deploy the database.
				$schema->deploy({ add_drop_table => 1 });

				# Execute the subtest.
				$code->($t, $schema);

				# This must be done here for postgres or exceptions are thrown after the test finishes in some cases
				# because the postgres daemon can stop before the Mojolicious app disconnects the schema from the
				# database.  It doesn't hurt for the others.
				$schema->storage->disconnect;
			}
		);
	}

	(shift @db_subtests)->finish while (@db_subtests);

	return;
}

1;
