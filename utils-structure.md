# utils-structure 

This document lays out the structure of the utils (utilities) needed for the webwork common.  This is an API for the middle layer.  

This needs access only to the database. 

Question: should this be the level of handling permissions?

## CourseUtils

* `getAllSets`
* `getAllUsers`
* `getCourseSettings`
* `updateCourseSettings`
* student progress/stats/scoring tools
* email utils
* get files in course directory
* 


## LibraryUtils

* `listLibraries`: list all libraries available to a course
* `getTaxonomy`: 
* `getSubjectProblems` : get all problems with given subject
* `getChapterProblems` : get all problems with given subject/chapter
* `getSectionProblems` : get all problems with given subject/chapter/section
* `getProblem`: get all problems matching metadata
* `searchLibrary`: general searching function
* `sortbyMLT`: sorts problem into More Like This (MLT) categories. 
* `getProblemTags` : gets all tags for a problem
* `getPGfilesInDir` : list of all PG files in a directory (local or in library)
* `get_set_defs`
* `munge_pg_file_paths`
* `find_dirs`
* `listLocalSets`
* `getLocalStats`
* `getGlobalStats`
* Tag utils (pulling from PG problems, cleaning)

## ProblemSetsUtils

* `getGlobalSet`
* `updateGlobalSet`
* `addGlobalSet`
* `deleteGlobalSet`
* `getUserSet`
* `updateUserSet`
* `addUserSet`
* `deleteUserSet`
* `getFakeSet`
* `assignSets`: assign sets to users
* `unassignSets`
* ways to produce hardcopies of sets

## ProblemUtils

* `getGlobalProblem`
* `updateGlobalProblem`
* `addGlobalProblem`
* `deleteGlobalProblem`
* `reorderProblems`
* `getUserProblem`
* `updateUserProblem`
* `addUserProblem`
* `deleteUserProblem`
* `getFakeProblem`
* `renderProblem` -- pull in Drew's standalone renderer code.

## GatewayQuizzes

Maybe we put these in a separate file in order to more easily upgrade this at a later time


## UserUtils

* `getUser`
* `updateUser`
* `addUser`
* `deleteUser`
* `getFakeUser`
* `checkPassword`
* `updatePassword`

## AdminUtils

* `getAllCourses`
* `getCourse`
* `addCourse`
* `updateCourse`
* `deleteCourse`
* `archiveCourse`
* `unarchiveCourse`
* `upgradeCourse`
* `checkCourseIntegrity`

## GeneralUtils

* international/translation utilities


