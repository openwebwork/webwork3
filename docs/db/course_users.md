# Courses and Users in WeBWorK 3

## Courses DB

fields

- `course_id` (PK, auto_increment)
- `course_name`
- `params`
  - `hidden`: boolean
  - `archived`: boolean

## Users DB (global users)

fields

- `user_id` (PK, auto_increment)
- `username`
  - what to allow (regexp)?
- `params`
  - `first_name`
  - `last_name`
  - `email`
  - `student_id`

## Course Users

This stores information about users in individual courses,
plus it is a many-to-many bridge table

fields

- `course_user_id` (KParker -- maybe not needed)
- `course_id`
- `user_id`
- `roles`
- `params`
  - `section`
  - `recitation`
  - `comment`
