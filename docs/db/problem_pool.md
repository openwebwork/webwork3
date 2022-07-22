# Problem Pools

A `ProblemPool` is a structure that is just a set of problems.
The purpose will be to select a problem at random.  Any
`ProblemSet` could select either a `Problem` with random seed
or a random problem from a `ProblemPool`.

## Problem Pool

The database structure of the pool (collection of problems)

### Problem Pool fields

- `problem_pool_id`: (PK, integer) the database key
- `course_id`: (FK, integer) the database id of the course.
- `name`: the name of the ProblemPool

### Note

- the problems in a pool are stored as `PoolProblems` (see below)

### Questions

1. should this be part of a course or global?

## Pool Problem

A problem in a ProblemPool.  See above for information about Problem Pools.

### Pool Problem fields

- `pool_problem_id`: (PK, integer) database id
- `problem_pool_id`: (FK, integer) the database id that this problem is in.
- `params`: (JSON string) stores one of
  - `library_id`: a database id of the problem
  - `problem_path`: path of the problem
