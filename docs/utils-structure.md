# utils-structure

This document lays out the structure of the utils (utilities)
needed for the webwork common.  This is an API for the middle
layer.

This needs access only to the database.

Question: should this be the level of handling permissions?

## AdminUtils

This set of subroutines handle all administration level (currently
everything in the admin course):

* `createCourse`
* `renameCourse`
* `deleteCourse`
* `upgradeCourse`
* `archiveCourse`
* `unarchiveCourse`
* `getAllCourses`
* `getCourse`
* `addCourse`
* `updateCourse`
* `upgradeCourse`
* `checkCourseIntegrity`

## UserUtils

Plans are to allow a server to setup with a global level of users.
These utils will handle the global users instead of the course Users:

* `getUsers` -- get all user data
* `getCourses(user_id)` -- get the courses that user `user_id` is enrolled.
* `createUser`
* `updateUser`
* `deleteUser`
* handle password for users (could be handled in `updateUser`)

## CourseUtils

* `getAllSets`
* `getAllUsers`
* `getCourseSettings`
* `updateCourseSettings`
* student progress/stats/scoring tools
* email utils
* file management (get/put files, move) in course directory

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

Maybe we put these in a separate file in order to more easily upgrade
this at a later time

## Achievements

* `getAllAchivementBadges`
* `getAllAchivementRewards`
* `getAchievementBadge`
* `getAchievementReward`

## CourseUserUtils

* `getUser`
* `updateUser`
* `addUser`
* `deleteUser`
* `getFakeUser`
* `checkPassword`
* `updatePassword`

## GeneralUtils

* international/translation utilities
