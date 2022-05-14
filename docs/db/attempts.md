# Attempts in WeBWorK3

This stores any submitted problem attempt from a user.

## fields

- `attempt_id`: (PK, integer) primary database id
- `user_problem_id`: the id of the UserProblem associated with the attempt.
- `attempt_params`: a JSON string that stores:
  - `weight`: weight of the problem
  - `library_id`: a database id of the problem
  - `problem_path`: path of the problem
  - `problem_pool_id`: database id of the problem in a pool.
- `user_input`: a JSON string that stores the user input.
- `attempt_type`: (string) type of input.

## Notes

- only one of the library_id, problem_path or problem_pool_id should be stored.
- do we need the `attempt_type` or only store submissions? Perhaps we can use this
  as an autosave as well.
