package WeBWorK3;
use Mojo::Base 'Mojolicious', -signatures;

use Mojo::File qw(curfile path);
use YAML::XS qw/LoadFile/;

BEGIN {
	use Env qw(WW3_ROOT);
	$WW3_ROOT = curfile->dirname->dirname->to_string;
}

use DB::Schema;
use WeBWorK3::Hooks;

# This method will run once at server start
sub startup ($self) {
	# log to file if we're in production mode
	if ($ENV{MOJO_MODE} && $ENV{MOJO_MODE} eq 'production') {
		my $path = path("$ENV{WW3_ROOT}/logs")->make_path->child('webwork3.log');
		$self->log->path($path);
	}

	# Load configuration from config file
	my $config = $self->plugin('NotYAMLConfig');

	# Configure the application
	$self->secrets($config->{secrets});

	# Load the database and DBIC plugin
	$self->plugin(
		DBIC => {
			schema => DB::Schema->connect(
				$config->{database_dsn}, $config->{database_user},
				$config->{database_password}, { quote_names => 1 }
			)
		}
	);

	# Load the authentication plugin
	$self->plugin(
		Authentication => {
			load_user     => sub ($app, $uid) { return $self->load_account($uid); },
			validate_user => sub ($c,   $u, $p, $e) { return $self->validate($u, $p); }
		}
	);

	# Set up the session
	$self->sessions->cookie_name('Webwork3Authen');
	$self->sessions->default_expiration($config->{cookie_lifetime});
	$self->sessions->cookie_path('/webwork3');
	$self->sessions->samesite($config->{cookie_samesite});
	$self->sessions->secure($config->{cookie_secure});

	# Handle all api route exceptions
	$self->hook(around_dispatch => $WeBWorK3::Hooks::exception_handler);

	$self->hook(around_action => $WeBWorK3::Hooks::check_permission);

	# Load all routes
	$self->loginRoutes();
	$self->permissionRoutes();
	$self->coursesRoutes();
	$self->userRoutes();
	$self->courseUserRoutes();
	$self->problemSetRoutes();
	$self->problemRoutes();
	$self->settingsRoutes();
	$self->utilityRoutes();
	return;
}

sub load_account ($self, $user_id) {
	my $course_id = $self->param('course_id');
	return $self->schema->resultset('User')->getGlobalCourseUser(
		info => {
			username  => $user_id,
			course_id => $course_id
		}
	) if defined $course_id;
	return $self->schema->resultset('User')->getGlobalUser(info => { username => $user_id });
}

sub validate ($self, $user, $password) {
	return $user if ($self->schema->resultset('User')->authenticate($user, $password));
	return;
}

sub loginRoutes ($self) {
	$self->routes->post('/webwork3/api/login')->to('Login#login');
	$self->routes->any('/webwork3/api/logout')->to('Login#logout_user');
	return;
}

sub permissionRoutes ($self) {
	$self->routes->get('/webwork3/api/roles')->to('Permission#getRoles');
	$self->routes->get('/webwork3/api/ui-permissions')->to('Permission#getUIRoutePermissions');
	return;
}

sub coursesRoutes ($self) {
	my $course_routes =
		$self->routes->any('/webwork3/api/courses')->requires(authenticated => 1)->to(controller => 'Course');
	$course_routes->get('/')->to(action => 'getCourses');
	$course_routes->get('/:course_id')->to(action => 'getCourse');
	$course_routes->put('/:course_id')->to(action => 'updateCourse');
	$course_routes->post('/')->to(action => 'addCourse');
	$course_routes->delete('/:course_id')->to(action => 'deleteCourse');
	return;
}

sub userRoutes ($self) {
	my $user_routes = $self->routes->any('/webwork3/api/users')->requires(authenticated => 1)->to(controller => 'User');
	$user_routes->get('/')->to(action => 'getGlobalUsers');
	$user_routes->post('/')->to(action => 'addGlobalUser');
	$user_routes->get('/:user_id')->to(action => 'getGlobalUser');
	$user_routes->put('/:user_id')->to(action => 'updateGlobalUser');
	$user_routes->delete('/:user_id')->to(action => 'deleteGlobalUser');
	$user_routes->get('/:user_id/courses')->to(action => 'getUserCourses');

	# This is used to check if a user with given username exists.
	$self->routes->get('/webwork3/api/courses/:course_id/users/:username/exists')->requires(authenticated => 1)
		->to('User#checkGlobalUser');
	return;
}

sub courseUserRoutes ($self) {
	my $course_user_routes =
		$self->routes->any('/webwork3/api/courses/:course_id')->requires(authenticated => 1)->to(controller => 'User');
	$course_user_routes->get('/users')->to(action => 'getCourseUsers');
	$course_user_routes->post('/users')->to(action => 'addCourseUser');
	$course_user_routes->get('/users/:user_id')->to(action => 'getCourseUser');
	$course_user_routes->put('/users/:user_id')->to(action => 'updateCourseUser');
	$course_user_routes->delete('/users/:user_id')->to(action => 'deleteCourseUser');

	# global user routes for accessing within a course for users with course roles.

	$course_user_routes->get('/global-courseusers')->to(action => 'getGlobalCourseUsers');
	$course_user_routes->post('/global-users')->to(action => 'addGlobalUser');
	$course_user_routes->get('/global-users/:user_id')->to(action => 'getGlobalUser');
	$course_user_routes->put('/global-users/:user_id')->to(action => 'updateGlobalUser');
	$course_user_routes->delete('/global-users/:user_id')->to(action => 'deleteGlobalUser');

	$course_user_routes->get('/courseusers')->to(action => 'getMergedCourseUsers');
	return;
}

sub problemSetRoutes ($self) {
	$self->routes->get('/webwork3/api/sets')->requires(authenticated => 1)->to('ProblemSet#getProblemSets');
	my $problem_set_routes =
		$self->routes->any('/webwork3/api/courses/:course_id/sets')->requires(authenticated => 1)
		->to(controller => 'ProblemSet');
	$problem_set_routes->get('/')->to(action => 'getProblemSets');
	$problem_set_routes->get('/:set_id')->to(action => 'getProblemSet');
	$problem_set_routes->put('/:set_id')->to(action => 'updateProblemSet');
	$problem_set_routes->post('/')->to(action => 'addProblemSet');
	$problem_set_routes->delete('/:set_id')->to(action => 'deleteProblemSet');

	# CRUD for User Sets
	$self->routes->get('/webwork3/api/courses/:course_id/user-sets')->to('ProblemSet#getAllUserSets');
	$problem_set_routes->get('/:set_id/users')->to(action => 'getUserSets');
	$problem_set_routes->post('/:set_id/users')->to(action => 'addUserSet');
	$problem_set_routes->put('/:set_id/users/:course_user_id')->to(action => 'updateUserSet');
	$problem_set_routes->delete('/:set_id/users/:course_user_id')->to(action => 'deleteUserSet');

	$self->routes->get('/webwork3/api/courses/:course_id/users/:user_id/sets')->to('ProblemSet#getUserSets');
	return;
}

sub problemRoutes ($self) {
	my $problem_routes = $self->routes->any('/webwork3/api/courses/:course_id')->requires(authenticated => 1)
		->to(controller => 'Problem');
	$problem_routes->get('/problems')->to(action => 'getAllProblems');
	$problem_routes->post('/sets/:set_id/problems')->to(action => 'addProblem');
	$problem_routes->put('/sets/:set_id/problems/:set_problem_id')->to(action => 'updateProblem');
	$problem_routes->delete('/sets/:set_id/problems/:set_problem_id')->to(action => 'deleteProblem');

	# UserProblem routes
	$problem_routes->get('/sets/:set_id/user-problems')->to(action => 'getUserProblemsForSet');
	$problem_routes->get('/users/:user_id/problems')->to(action => 'getUserProblemsForUser');
	$problem_routes->post('/sets/:set_id/users/:user_id/problems')->to(action => 'addUserProblem');
	$problem_routes->put('/sets/:set_id/users/:user_id/problems/:user_problem_id')->to(action => 'updateUserProblem');
	$problem_routes->delete('/sets/:set_id/users/:user_id/problems/:user_problem_id')
		->to(action => 'deleteUserProblem');

	return;
}

sub settingsRoutes ($self) {
	$self->routes->get('/webwork3/api/courses/:course_id/default_settings')->requires(authenticated => 1)
		->to('Settings#getDefaultCourseSettings');
	$self->routes->get('/webwork3/api/courses/:course_id/settings')->requires(authenticated => 1)
		->to('Settings#getCourseSettings');
	$self->routes->put('/webwork3/api/courses/:course_id/setting')->requires(authenticated => 1)
		->to('Settings#updateCourseSetting');
	return;
}

sub utilityRoutes ($self) {
	$self->routes->post('/webwork3/api/client-logs')->requires(authenticated => 1)->to('Logger#clientLog');
	return;
}

1;
