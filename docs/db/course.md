# Course table

This is a listing of the fields in courses table

- `course_id`: integer, auto-increment
- `course_name`: string, (limit characters?)


## Course Parameters

Possibly put course parameters in a separate database

### General

- `course_description`: string
- `institution`: string
- `visible`: boolean
- `theme`: set of options
- `language`: set of options (or should this be a user setting?)
- `lang_dir` (attached to `language`)
- `inactivity_time` : integer (in seconds)
- `timezone`: string
- `hardcopy_theme`: set of options
- `use_date_picker`: boolean (needed?)
- `homework_totals`: boolean (needed?)
- `hw_progress_bar`: boolean (needed?)
- `default_due_time`: time
- `default_time_open`: time duration
- `default_time_answer`: time duration

### Optional Modules

- `enable_conditional_release`

#### Reduced Scoring

- `enable_reduced_scoring`: boolean
- `reducing_scoring_value`: integer (as a percent)
- `default_time_reduced_scoring`: time duration

#### Show Me Another

- `enable_show_me_another`: boolean
- `show_me_another_attempts`: integer
- `show_me_another_max_attempts`: integer
- `show_me_another_options`: set of options

#### Rerandomization

- `enable_periodic_randomization`: boolean
- `rerandomization_attempts_default`: integer
- `rerandomization_show_correct_ans`: boolean

#### Achievements

Achievements should be a separate module that can be loaded as needed.

- `enable_course_achievements`: boolean (make as a module)
- `achievement_pts_per_problem`: integer
- `enable_conditional_release`: boolean


### Permissions

This needs to be rethought.  Perhaps a table of permissions versus course roles.

### Answer Options

- `display_mode_options`: set of options  (perhaps not needed?)
- `default_display_mode`: one of the above options
- `student_answer_entries`: set of options
- `display_student_answer`: boolean
- `log_base`: set of (e, 10)
- `allow_unicode` : boolean
- `full_width_unicode`: boolean
- `relative_answer_error`: decimal
- `skip_explain_essay`: false

### Email

- `email_subject_format`: string
- `email_verbosity`: set of options
- `email_from_pg`: string (list of email addresses)
- `email_automatic`: set of course roles
- `email_additional`: string (list of email addresses)
- `email_feedback_section`: boolean