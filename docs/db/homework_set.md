# HomeworkSet

This basically mimics a WeBWorK2 homework set

## fields

- `type`: `HW`
- `dates`:
  - `open` (**required**)
  - `reduced_scoring`
  - `due` (**required**)
  - `answer` (**required**)

- `params`:
  - `visible`: (default: false)
  - `problem_view`: (default: `one_per_page`)

## JITAR (Just in Time Set)

(inherits from HWSet)

- `type`: `JITAR`
