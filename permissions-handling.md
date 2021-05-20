## Handling Permissions or Roles

In seems that this restructuring gives us the opportunity to rethink the handling of permissions and roles.  Instead of a numerical value of the roles, we can build a table of tasks (or sets of functions) that each role can employ.  


### Current Roles 

- Guest
- Student
- login_proctor 
- grade_proctor
- TA
- professor
- admin


### Tasks

We want to allow/limit authorization of each of the subroutines in the utilities structure.  This could be a lookup table for allowed subroutines to run or either a white or blacklist.  

For example 

- `tasks('admin')` would authorize all subroutines
- `tasks('professor')` would authorize all course subroutines, but exclude admin-level subroutines. 


