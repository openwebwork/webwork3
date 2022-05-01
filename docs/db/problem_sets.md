# Problem Sets

This describes the database structure on both the database and the client.  In
general, the names are equivalent, but sometimes for clarify are changed.

A `ProblemSet` will be the top-most class that all other classes
will inherit from. All inherited ProblemSets will be stored in a
single table `problem_sets` and all will have the following fields

## fields

- `problem_set_id`: (PK, auto_increment)
- `course_id`: course that the set is in
- `name`: Name of the Problem set   (course_id + name needs to be unique)
- `type`: type of ProblemSet (Homework, Quiz, Review Set, etc. )
- `dates`: hash of dates (due, open, reduced_scoring, answer), store as JSON
- `params`: hash of other parameters depending on type stores as a JSON.

## Subclasses of ProblemSets

- `HomeworkSet`: this is the class WeBWorK2 homework set
- `Quiz`: this will cover both gateway quizzes from webwork2, as well as more
generic quiz types.
- `ReviewSet`: this is intended to be a set of problems that are not to have grades
stored.

## UserSets

A `UserSet` is a generic user version of a `ProblemSet`.  The creation of a `UserSet`
for a user is to assign a user to a `ProblemSet`. This also allows versioning.  The
fields of a `UserSet` are

- `user_set_id`: (PK, auto_increment)
- `set_id`: (foreign key), the problem set that is associated with this user set
- `course_user_id`: (foreign key), the `CourseUser` that this is associated with. That
is who is assigned to this set.
- `set_version`: the version of the set.  Used for Gateway quizzes or other problem sets.
- `set_type`: the type of the set.  This must be the same as the set type of the `ProblemSet`.
- `set_visible`: a boolean. If true, have the set visible.
- `set_params`: a hash (object) of parameters for the set.  These will override the `set_params` field in the corresponding problem set.
- `set_dates`: a hash (object) of dates for the set.  These will override the `set_dates` field in the corresponding problem set.

## Questions

1. How to do versioning? DG suggested version everything and then it's just
  built-in.
2. How to handle show me another problems/homework sets? (if everything is
  versioned, this may be built-in)
3. How to handle Gateway Quizzes?
4. How to handle JITAR homework Sets.  (Is this really different or possibly
  need to think about a way to store the problem tree)
