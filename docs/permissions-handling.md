## Handling Permissions or Roles

In seems that this restructuring gives us the opportunity to rethink the handling of permissions and roles.  Instead of a numerical value of the roles, we can build a table of permissions and tasks (or sets of functions) that each role can employ.  


### Permissions

A permission is the allowance of function calls. For example, allow to create a homework set.  These are typically database-level structures 

### Tasks

Tasks are things to be done.  Record a submission is an example.  

### Roles

A role will be a set of permissions and tasks. 

#### Current Roles  (Group of Permssions)

- Guest
- Student
- login_proctor 
- grade_proctor
- TA
- professor
- admin


### Ability to create other roles

If the default roles do not apply, there should be the flexibility to create other roles that will have permissions and tasks.  


### Storage

The role needs to be stored as a lookup table of permissions and tasks.   It's unclear if this needs to be in the database or config files.  
