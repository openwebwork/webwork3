# Tests for WeBWorK 3

The subdirectories within this directory contain various tests for WeBWorK 3 including:

* `db`: which directly tests the database.
* `mojolicious`: which tests the UI and api (REST services).

## db subdirectory

All of the database tests rely on a sqlite database file called `sample_db.sqlite`.
If this does not exist or perhaps needs to be rebuilt, run `perl build_db.pl`.  This
will take data in CSV files in the `sample_data` directory and fill the database.

All tests within the directory can be run with either `prove *.t` or `prove -lv *.t`,
where the first runs all tests within all test files and just reports a summary of
the results.  The command with the `-lv` flags lists things test by test and any
output from the tests.

Additional, one can run an individual test as in the following  example
`prove -lv 001_courses.t`.

## mojolicious subdirectory

The tests in here use the testing ability built into Mojolicious, specifically
`Mojo::Test`.  This spins up a mojolicious server and makes various server calls
and tests the results.

Like above the tests rely on the `sample_db.sqlite` database and it must be built
or rebuilt.

All tests within the directory can be run with either `prove *.t` or `prove -lv *.t`,
where the first runs all tests within all test files and just reports a summary of
the results.  The command with the `-lv` flags lists things test by test and any
output from the tests.

Additional, one can run an individual test as in the following  example
`prove -lv 001_login.t`.
