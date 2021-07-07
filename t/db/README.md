# README for the testing db

This directory contains numerous tests for the database interactions.

To run all of the tests, enter `perl run_all_tests.pl`.

This does the following

1. If the file `sample_db.sqlite` does not exist, then the database is
rebuilt with the script `build_db.pl`.  This loads all of the data from
the `sample_data` directory into a sqlite database.

2. Each of the test files (with suffix `.t`) is run.

## Alternative

You can also run an individual test script such as `perl 002_users.t`.
This is what is usually done when working on a certain perl module.

### Note

If you get an error, either delete the `sample_db.sqlite` file or run
`perl build_db.pl` to see if the database and data are out of sync.

### To do

1. Adding new tests to individual files to ensure coverage.
2. Add new test files for new database functionality.
3. switch to a mysql or mariadb database, instead of a sqlite
