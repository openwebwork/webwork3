# Problem Pool

A `ProblemPool` is a structure that is just a set of problems.
The purpose will be to select a problem at random.  Any
`ProblemSet` could select either a `Problem` with random seed
or a random problem from a `ProblemPool`.

## fields

- `problem_pool_id`: the database key
- `name`: the name of the ProblemPool
- `problems`: an array of problem_info (library_id or
problem_path).

## Questions

1. should this be part of a course or global?
2. How to store the problems?  Could be a JSON strucure
  alternatively there could be a second table that stores
  the problems
