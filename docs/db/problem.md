# Problems in WeBWorK3

There are a number of problems (problem types). What they all have in common is
the ability to be rendered.  See below about Render parameters.

## Problem Types

### Set Problem

A SetProblem is a problem in a ProblemSet.  It needs to be stored in the database.

#### fields for a SetProblem

- `problem_id`: (PK, integer) database id
- `set_id`: (PK, integer) the database id of the set the problem is in.
- `problem_number`: (non-neg integer) the number of the problem
- `problem_params`:
  - `weight`: the possible number of points for the problem.
  - `problem_path`: the path of the problem in the OPL/locally.
  - `library_id`: a database id of the problem
  - `pool_problem_id`: a database id of a problem pool.

### LibaryProblem

This is a problem in the library.  It is not in the standard webwork database, but in
the OPL database instead.  See OPLv3 repository.

### UserProblem

A UserProblem is a problem for a user. It is used as 1) a way to override most
parameters from a SetProblem and 2) to store the current value of the problem
for the user.

#### UserProblem fields

- `user_problem_id`: (PK, integer) database id
- `problem_id`: (FK, integer) database id of the set problem this comes from.
- `user_set_id`:
- `seed`:
- `status`: current value of the problem
- `problem_version`: version of the problem (useful for gateway quizzes)
- `problem_params`: problem params for overrides.

#### Question

1. Is the status field the best way to store the current problem value for a user.
  Perhaps this goes better elsewhere (attempt?).
2. How to handle reduced scoring?  Do we store two values?
