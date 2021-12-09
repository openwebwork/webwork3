# Problems

## Common fields

All problem objects must have the following fields:
* problem path / library ID

## Problem Types

### Library

For browsing the OPL/Contrib
* non-interactive
* show all hints/solutions
* wrapper with view/edit/shuffle buttons

### Homework

* interactive
* includes current state (attempts info)
* submitted individually
* scores recorded (weight)

### Review

* interactive
* includes hints (solutions?)
* re-randomizable
* submitted individually
* scores not recorded (no weight, state, or attempt data)

### Quiz / Exam

* interactive
* hints according to settings
* no solutions
* not rerandomizable
* submitted as a collection
* scores recorded (problem state)
* attempt data belongs to collection
* weights belong to collection
