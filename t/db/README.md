# README for the testing db

This directory contains numerous tests for the database interactions. To run the tests,
`cd` to the top level of the webwork3 directory.

1. Run  `cp conf/ww3-dev.dist.yml conf/ww3-dev.yml`.  This makes a copy of a configuration
file that the testing uses.  You can look in that file and make any desired changes.

2. Run `perl t/db/build_db.pl`.  This runs a script which restores the database and
fills the database with data from the `t/db/sample_data` directory.

3. `prove -r t` which runs all tests in the `t` directory.

## Alternative

You can also run an individual test script such as `prove -v t/db/003_users.t`.
This produces a verbose (`-v`) version of the tests and lists the output of
each test.

## Note

If you get an error, try rerunning steps 2 and 3 above.  This rebuids the database
and reruns all of the tests.

## To do

1. Adding new tests to individual files to ensure coverage.
2. Add new test files for new database functionality.
