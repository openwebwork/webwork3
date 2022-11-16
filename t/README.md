# Tests for WeBWorK 3

The subdirectories within this directory contain various tests for WeBWorK3 including:

- `db`: which directly tests the database.
- `mojolicious`: which tests the UI and API (REST services).

To run all of the tests execute `prove -r t`. For more verbose output execute `prove -rv t`. Individual tests can be
run with `prove t/db/001_courses.t`, for example.

By default all tests are executed once with an in memory sqlite database. However, if the environment variable
`WW3_TEST_ALL_DBS` is set, then each test is executed three times, first with the in memory sqlite database, then with a
temporary postgres database instance, and then with a temporary mysql database instance. For example, execute
`WW3_TEST_ALL_DBS=1 prove -r t` or `WW3_TEST_ALL_DBS=1 prove -v t t/db/001_courses.t`.

## db subdirectory

Many of the database tests rely on data in JSON files in the `sample_data` directory. Each test populates the database
with the sample data it needs.

## mojolicious subdirectory

The tests in here use the testing ability built into Mojolicious, specifically `Mojo::Test`. This spins up a
Mojolicious server and makes various server calls and tests the results.

Many of these tests also rely on data in JSON files in the `sample_data` directory, and each test populates the database
with the sample data it needs.

## TODO

1. Add new tests to individual files to ensure coverage.
2. Add new test files for new database functionality.
