# Database Interaction

The specifics of interacting with the CRUD (create, retrieve, update, delete)
actions of the database are located in the perl POD files (location?)  The document
explains the overview of the database interations.

Most of the database tables have a getter interaction for fetching a collection of
rows and the four standard interactions.

## Fetching a collection

For many of the database tables, a collection of rows can be retrieved.  In each
case the `info` field is used.

For example, the following selects all Problem Sets (homework sets, quizzes, etc.)
for a given course.

```perl
getProblemSets(info => { course_name => "Precalculus" });
```

## Single row interactions

The following are single row interactions for getting, adding, updating and deleting.

### Getting/Retrieving

A getter interaction is prefixed with `get`. The information needed for the getter
is passed in with the `info` field which is a hashref.

For example, if we wish to retrieve the problem set called 'HW #1' in the course
'Precalculus', you would make the call,

```perl
getProblemSet(info => { set_name => "HW #1", course_name => "Precalculus" });
```

### Adding/Creating

Adding to a database is prefixed with `add`. The information needed to add is
passed in with the `params` field which is a hashref.

For example, if we wish to add a problem set to the course 'Precalculus', the
following is an example:

```perl
addProblemSet(params => {
  course      => "Precalculus",
  set_name    => "HW #11",
  set_dates   => { open => 100, due => 140, answer => 10 },
  set_type    => "HW",
  set_visible => 1,
  set_params  => {}
});
```

### Updating

Updating a row in the database is prefixed with `update`. The information to determine
the row that needs updating is passed in with `info` and information about the
updated parameters is passed in with `params`.

For example, updating the above Problem Set can be made with

```perl
updateProblemSet(info => {
  course    => "Precalculus",
  set_name  => "HW #11"
},
params => {
  set_dates => {
    open => 1234,
    reduced_scoring => 1500,
    due => 2000,
    answer => 2500
  },
  set_params => {
    enable_reduced_scoring => 1
  }
});
```

### Deleting

Deleting a row in the database if prefixed with `delete`. The information to determine
the row to delete is like the getter and passed in with `info`.

An example of deleting the above problem set is

```perl
deleteProblemset(info => {
  course    => "Precalculus",
  set_name  => "HW #11"
});
```

## Other arguments to these commands

In addition, there is a `as_result_set` argument to every database command.  If this
is set to true (1), then the result is a ResultSet in terms of DBIx::Class.  See
[https://metacpan.org/pod/DBIx::Class::ResultSet](https://metacpan.org/pod/DBIx::Class::ResultSet) for more information.
