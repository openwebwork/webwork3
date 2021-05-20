## Collections in WeBWorK

This is a data structure that is a bunch of problems.  There are a number of existing structures that fall into this:
- HomeworkSet
- GatewayQuiz
- ProctoredGatewayQuiz
- JITAR set
- showMeAnother (?)


Each one of these is separate although there is some common structure.  If we create an `AbstractProblemSet` class, then each of these can inherit a lot of the structure from the top class. 

This will also allow the generation of other structures more easily including


### New Collections

- ProblemPool: a set of problems that other collections can pull from
- ReviewSet: a set of problems that isn't scored and can be done randomly.
- Quiz: A more-simple-than the gateway quiz,  timed quiz 

### AbstractProblemSet

Common properties/methods:

- set of problems

- `addProblem`
- `deleteProblem`
- 


#### Homework Set

- the problems are sequential 
- mapping between the order and the set.  


#### ProblemPool

- `getRandomProblem`x