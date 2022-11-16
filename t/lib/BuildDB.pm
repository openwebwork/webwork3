package BuildDB;
use parent Exporter;

# This package provides methods for deploying the webwork3 database, and filling it with sample data.

use Mojo::Base -signatures;
use Carp;
use Mojo::JSON qw/decode_json/;

use DB::Utils qw/updatePermissions/;

our @EXPORT_OK =
	qw/loadPermissions addCourses addUsers addSets addProblems addUserSets addProblemPools addUserProblems/;

sub loadPermissions ($schema, $ww3_dir) {
	updatePermissions($schema, $ww3_dir->child('conf/permissions.dist.yml'));
	return;
}

sub addCourses ($schema, $ww3_dir) {
	my $course_rs = $schema->resultset('Course');
	my $courses   = decode_json($ww3_dir->child('t/db/sample_data/courses.json')->slurp);
	$course_rs->create($_) for @$courses;
	return;
}

# Note that loadPermissions and addCourses must be called before calling addUsers.
sub addUsers ($schema, $ww3_dir) {
	my $course_rs = $schema->resultset('Course');
	my $role_rs   = $schema->resultset('Role');

	my $users = decode_json($ww3_dir->child('t/db/sample_data/users.json')->slurp);

	for my $user (@$users) {
		my $courses = delete $user->{courses};
		if (defined $courses) {
			for my $course_data (@{$courses}) {
				my $course = $course_rs->find({ course_name => $course_data->{course_name} });
				croak qq{The course "$course_data->{course_name}" does not exist.} unless defined $course;

				my $course_user = $course_data->{course_user};

				# Look up the role of the user
				my $role = $role_rs->find({ role_name => $course_user->{role} });
				croak qq{The role "$course_user->{role}" for user "$user->{username}" does not exist.}
					unless defined $role;

				delete $course_user->{role};
				$course_user->{role_id} = $role->role_id;
				$user->{login_params}   = { password => $user->{username} };

				$course->add_to_users($user, $course_user);
			}
		} else {
			$user->{login_params} = { password => $user->{username} };
			$schema->resultset('User')->create($user);
		}
	}
	return;
}

# Note that addCourses must be called before calling addSets.
sub addSets ($schema, $ww3_dir) {
	my $course_rs = $schema->resultset('Course');

	# Add homework sets
	my $course_hw_sets = decode_json($ww3_dir->child('t/db/sample_data/hw_sets.json')->slurp);
	for my $course_data (@$course_hw_sets) {
		my $course = $course_rs->find({ course_name => $course_data->{course_name} });
		croak qq{The course "$course_data->{course_name}" does not exist.} unless defined $course;
		for (@{ $course_data->{sets} }) {
			$course->add_to_problem_sets($_);
		}
	}

	# Add quizzes
	my $course_quizzes = decode_json($ww3_dir->child('t/db/sample_data/quizzes.json')->slurp);
	for my $course_data (@$course_quizzes) {
		my $course = $course_rs->find({ course_name => $course_data->{course_name} });
		croak qq{The course "$course_data->{course_name}" does not exist.} unless defined $course;
		for (@{ $course_data->{sets} }) {
			$_->{type} = 2;
			$course->add_to_problem_sets($_);
		}
	}

	# Add review sets
	my $course_review_sets = decode_json($ww3_dir->child('t/db/sample_data/review_sets.json')->slurp);
	for my $course_data (@$course_review_sets) {
		my $course = $course_rs->find({ course_name => $course_data->{course_name} });
		croak qq{The course "$course_data->{course_name}" does not exist.} unless defined $course;
		for (@{ $course_data->{sets} }) {
			$_->{type} = 4;
			$course->add_to_problem_sets($_);
		}
	}

	return;
}

# Note that addCourses and addSets must be called before calling addProblems.
sub addProblems ($schema, $ww3_dir) {
	my $problem_set_rs = $schema->resultset('ProblemSet');

	my $course_set_problems = decode_json($ww3_dir->child('t/db/sample_data/problems.json')->slurp);
	for my $course_data (@$course_set_problems) {
		for my $set_data (@{ $course_data->{sets} }) {
			# Check if a course with course_name exists with the set set_name.
			my $set =
				$problem_set_rs->find(
					{ 'me.set_name' => $set_data->{set_name}, 'courses.course_name' => $course_data->{course_name} },
					{ join          => 'courses' });
			croak qq{The course "$course_data->{course_name}" with set "$set_data->{set_name}" does not exist.}
				unless defined $set;

			for (@{ $set_data->{problems} }) {
				$set->add_to_problems($_);
			}
		}
	}
	return;
}

# Note that all of the previous methods must be called before calling addUserSets.
sub addUserSets ($schema, $ww3_dir) {
	my $course_rs      = $schema->resultset('Course');
	my $course_user_rs = $schema->resultset('CourseUser');

	my $course_set_users = decode_json($ww3_dir->child('t/db/sample_data/user_sets.json')->slurp);

	for my $course_data (@$course_set_users) {
		# Check if the course exists.
		my $course = $course_rs->find({ course_name => $course_data->{course_name} });
		croak qq{The course "$course_data->{course_name}" does not exist.} unless defined $course;

		for my $set_data (@{ $course_data->{sets} }) {
			# Check if the set exists.
			my $set = $schema->resultset('ProblemSet')
				->find({ course_id => $course->course_id, set_name => $set_data->{set_name} });
			croak qq{The set "$set_data->{set_name}" does not exist.} unless defined $set;

			for my $user_data (@{ $set_data->{users} }) {
				# Check if the user exists and is in the course.
				my $user = $course->users->find({ username => $user_data->{username} });
				croak qq{The user "$user_data->{username}" does not exist.} unless defined $user;

				my $course_user = $user->course_users->find({ course_id => $course->course_id });
				croak qq{The course user "$user_data->{username}" does not exist }
					. qq{in the course "$course_data->{course_name}".}
					unless defined $course_user;

				$user_data->{user_set}{course_user_id} = $course_user->course_user_id;
				$set->add_to_user_sets($user_data->{user_set});
			}
		}
	}
	return;
}

# Note that addCourses must be called before calling addProblemPools.
sub addProblemPools ($schema, $ww3_dir) {
	my $course_rs       = $schema->resultset('Course');
	my $problem_pool_rs = $schema->resultset('ProblemPool');

	my $course_pool_problems = decode_json($ww3_dir->child('t/db/sample_data/pool_problems.json')->slurp);

	for my $course_info (@$course_pool_problems) {
		my $course = $course_rs->find({ course_name => $course_info->{course_name} });
		croak qq{The course "$course_info->{course_name}" does not exist.} unless defined $course;

		for my $problem_pool_info (@{ $course_info->{pools} }) {
			my $problem_pool =
				$problem_pool_rs->create(
					{ course_id => $course->course_id, pool_name => $problem_pool_info->{pool_name} });
			for (@{ $problem_pool_info->{pool_problems} }) {
				$problem_pool->add_to_pool_problems($_);
			}
		}
	}
	return;
}

# Note that all of the previous methods except addProblemPools must be called before calling addUserProblems.
sub addUserProblems ($schema, $ww3_dir) {
	my $user_set_rs    = $schema->resultset('UserSet');
	my $set_problem_rs = $schema->resultset('SetProblem');

	my $course_set_problem_user_problems = decode_json($ww3_dir->child('t/db/sample_data/user_problems.json')->slurp);

	for my $course_info (@$course_set_problem_user_problems) {
		for my $set_info (@{ $course_info->{sets} }) {
			for my $problem_info (@{ $set_info->{problems} }) {
				my $problem = $set_problem_rs->find(
					{
						'courses.course_name'  => $course_info->{course_name},
						'problem_set.set_name' => $set_info->{set_name},
						'problem_number'       => $problem_info->{problem_number}
					},
					{ join => { 'problem_set' => 'courses' } }
				);

				for my $user_info (@{ $problem_info->{users} }) {
					$user_set_rs->find(
						{
							'users.username'       => $user_info->{username},
							'courses.course_name'  => $course_info->{course_name},
							'problem_set.set_name' => $set_info->{set_name}
						},
						{ join => [ { problem_set => 'courses' }, { course_users => 'users' } ] }
					)->add_to_user_problems({
							set_problem_id => $problem->set_problem_id,
							%{ $user_info->{user_problem} }
					});

				}
			}
		}
	}
	return;
}

1;
