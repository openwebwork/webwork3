# Problem Sets

A `ProblemSet` will be the top-most class that all other classes
will inherit from. All inherited ProblemSets will be stored in a
single table `problem_sets` and all will have the following fields

## fields

- `problem_set_id`: (PK, auto_increment)
- `course_id`: course that the set is in
- `name`: Name of the Problem set   (course_id + name needs to be unique)
- `set_version`: version of the set (default = 1)
- `type`: type of ProblemSet (Homework, Quiz, Gateway Quiz, etc. )
- `dates`: hash of dates (due, open, reduced_scoring, answer), store as JSON
- `params`: hash of other parameters depending on type

## Subclasses of ProblemSets

- `HomeworkSet`: this is the class WeBWorK2 homework set
- `Quiz`:

## Questions

1. How to do versioning? DG suggested version everything and then it's just
  built-in.
2. How to handle show me another problems/homework sets? (if everything is
  versioned, this may be built-in)
3. How to handle Gateway Quizzes?
4. How to handle JITAR homework Sets.  (Is this really different or possibly
  need to think about a way to store the problem tree)
