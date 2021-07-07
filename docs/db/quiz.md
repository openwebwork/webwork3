# Quiz

## fields

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
