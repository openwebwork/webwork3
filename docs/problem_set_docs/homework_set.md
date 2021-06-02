## HomeworkSet

This basically mimics a WeBWorK2 homework set

### fields

- `type`: `HW`

- `dates`:
  - `open` (**required**)
  - `reduced_scoring`
  - `due` (**required**)
  - `answer` (**required**)

- `params`:
  - `visible`: (default: false)
  - `problem_view`: (default: `one_per_page`)

## ReviewSet

- `type`: `REVIEW`
- `dates`:
  - `open`: (**required**)
  - `closed`: 

## Quiz

### fields

- `type`: `QUIZ`
- `dates`: 
  - `open`:  (**required**) 
  - `due`: (**required**)
  - `answer`:  (**required**)
- `params`:
  - `timed`:  (default: `true` )
  - `time_length`: default: `30`
  - `problem_view`: (default: `one_per_page`)

## GatewayQuiz

(inherits from Quiz)

- `type`: `GWQ`
- `params`:
  - `version`: 

## JITAR (Just in Time Set)

(inherits from HWSet)

- `type`: `JITAR`