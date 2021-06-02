## Structure of a Problem Set

A `ProblemSet` will be the top-most class 

### fields

- `problem_set_id`: the database key
- `course_id`: course that the set is in
- `name`: Name of the Problem set 
- `type`: type of ProblemSet (Homework, Quiz, Gateway Quiz, etc. )
- `dates`: hash of dates (due, open, reduced_scoring, answer), store as JSON
- `params`: hash of other parameters depending on type




## Problem Pool

A `ProblemPool` is a structure that is just a set of problems.  The purpose will be to select a problem at random.  

### fields

- `problem_pool_id`: the database key
- `name`: the name of the ProblemPool
- `problems`: an array of problem_ids.  (JSON structure?)


#### Questions

- should this be part of a course or global? 