package WeBWorK3;
use Mojo::Base 'Mojolicious', -signatures;

use Mojo::File qw/curfile path/;
use YAML::XS qw/LoadFile/;

use DB::Schema;
use WeBWorK3::Hooks;

# This method will run once at server start
sub startup ($app) {
	# Pick the config file to use and set up logging dependant on the mode being run in.
	my $config_file;
	if ($ENV{MOJO_MODE} && $ENV{MOJO_MODE} eq 'production') {
		$app->log->path($app->home->child('logs', 'webwork3.log'));

		$config_file = $app->home->child('conf', 'webwork3.yml');
		$config_file = $app->home->child('conf', 'webwork3.dist.yml') unless -e $config_file;
	} elsif ($ENV{MOJO_MODE} && $ENV{MOJO_MODE} eq 'test') {
		$app->log->path($app->home->child('logs', 'webwork3_test.log'));
		$app->log->level('trace');

		$config_file = $app->home->child('conf', 'webwork3-test.yml');
		$config_file = $app->home->child('conf', 'webwork3-test.dist.yml') unless -e $config_file;
		$app->plugin(NotYAMLConfig => { file => $config_file });
	} else {
		$config_file = $app->home->child('conf', 'webwork3-dev.yml');
		$config_file = $app->home->child('conf', 'webwork3.yml')      unless -e $config_file;
		$config_file = $app->home->child('conf', 'webwork3.dist.yml') unless -e $config_file;
	}

	# Load configuration from config file
	my $config = $app->plugin(NotYAMLConfig => { file => $config_file });

	# Configure the application
	$app->secrets($config->{secrets});

	# Load the database and DBIC plugin
	$app->plugin(
		DBIC => {
			schema => DB::Schema->connect(
				$config->{database_dsn}, $config->{database_user},
				$config->{database_password}, { quote_names => 1 }
			)
		}
	);

	# Load the authentication plugin
	$app->plugin(
		Authentication => {
			load_user     => sub ($c, $uid) { return $app->load_account($c, $uid); },
			validate_user => sub ($c, $u, $p, $e) { return $app->validate($u, $p); }
		}
	);

	# Set up the session
	$app->sessions->cookie_name('Webwork3Authen');
	$app->sessions->default_expiration($config->{cookie_lifetime});
	$app->sessions->cookie_path('/webwork3');
	$app->sessions->samesite($config->{cookie_samesite});
	$app->sessions->secure($config->{cookie_secure});

	# Handle all api route exceptions
	$app->hook(around_dispatch => $WeBWorK3::Hooks::exception_handler);
	$app->hook(after_dispatch  => $WeBWorK3::Hooks::notify_expiry);

	# The following defines the routes as well as handles whether a user has permission for each route
	# The following routes need no authentication:
	$app->loginRoutes();
	$app->utilityRoutes();

	# These only require authentication.
	my $authen_routes = $app->routes->any('webwork3/api')->requires(authenticated => 1);
	permissionRoutes($authen_routes);

	# The following routes are global, so can only be accessed with admin privileges.
	my $global_routes =
		$app->routes->under('webwork3/api')->requires(authenticated => 1)->to('Permission#checkPermission');
	coursesRoutes($global_routes);
	userRoutes($authen_routes, $global_routes);

	# The following courses are within courses, so we need more substantial checking
	my $course_routes = $app->routes->under('/webwork3/api/courses/:course_id')->requires(authenticated => 1)
		->to('Permission#checkPermission');
	$app->courseUserRoutes($course_routes);
	$app->problemSetRoutes($course_routes);
	$app->problemRoutes($course_routes);
	$app->settingsRoutes($course_routes);

	return;
}

sub load_account ($app, $c, $username) {
	my $course_id = $c->param('course_id');
	return $c->schema->resultset('User')->getGlobalCourseUser(
		info => {
			username  => $username,
			course_id => $course_id
		}
	) if defined $course_id;
	return $c->schema->resultset('User')->getGlobalUser(info => { username => $username });
}

sub validate ($app, $user, $password) {
	return $user if ($app->schema->resultset('User')->authenticate($user, $password));
	return;
}

sub loginRoutes ($app) {
	$app->routes->post('/webwork3/api/login')->to('Login#login');
	$app->routes->any('/webwork3/api/logout')->to('Login#logout_user');
	return;
}

sub permissionRoutes ($authen_routes) {
	$authen_routes->get('/roles')->to('Permission#getRoles');
	$authen_routes->get('/ui-permissions')->to('Permission#getUIRoutePermissions');
	return;
}

sub coursesRoutes ($global_routes) {
	$global_routes->get('/courses/')->to('Course#getCourses');
	$global_routes->get('/courses/:course_id')->to('Course#getCourse');
	$global_routes->put('/courses/:course_id')->to('Course#updateCourse');
	$global_routes->post('/courses')->to('Course#addCourse');
	$global_routes->delete('/courses/:course_id')->to('Course#deleteCourse');
	return;
}

sub userRoutes ($authen_routes, $global_routes) {
	$global_routes->get('/users')->to('User#getGlobalUsers');
	$global_routes->post('/users')->to('User#addGlobalUser');
	$global_routes->get('/users/:user_id')->to('User#getGlobalUser');
	$global_routes->put('/users/:user_id')->to('User#updateGlobalUser');
	$global_routes->delete('/users/:user_id')->to('User#deleteGlobalUser');
	$authen_routes->under('/users/:user_id')->to('Permission#checkPermission')->get('/courses')
		->to('User#getUserCourses');
	return;
}

sub courseUserRoutes ($app, $course_routes) {
	$course_routes->get('/users')->to('User#getCourseUsers');
	$course_routes->post('/users')->to('User#addCourseUser');
	$course_routes->get('/users/:user_id')->to('User#getCourseUser');
	$course_routes->put('/users/:user_id')->to('User#updateCourseUser');
	$course_routes->delete('/users/:user_id')->to('User#deleteCourseUser');

	# global user routes for accessing within a course for users with course roles.

	$course_routes->get('/global-courseusers')->to('User#getGlobalCourseUsers');
	$course_routes->post('/global-users')->to('User#addGlobalUserFromCourse');
	$course_routes->get('/global-users/:user_id')->to('User#getGlobalUserFromCourse');
	$course_routes->get('/global-users/:user_id/courses')->to('User#getUserCoursesFromCourse');
	$course_routes->put('/global-users/:user_id')->to('User#updateGlobalUserFromCourse');
	$course_routes->delete('/global-users/:user_id')->to('User#deleteGlobalUserFromCourse');

	$course_routes->get('/courseusers')->to('User#getMergedCourseUsers');

	# This is used to check if a user with given username exists.
	$course_routes->get('/users/:username/exists')->to('User#checkGlobalUser');

	return;
}

sub problemSetRoutes ($app, $course_routes) {
	$course_routes->get('/sets')->to('ProblemSet#getProblemSets');
	$course_routes->get('/sets/:set_id')->to('ProblemSet#getProblemSet');
	$course_routes->put('/sets/:set_id')->to('ProblemSet#updateProblemSet');
	$course_routes->post('/sets')->to('ProblemSet#addProblemSet');
	$course_routes->delete('/sets/:set_id')->to('ProblemSet#deleteProblemSet');

	# CRUD for User Sets
	$course_routes->get('/user-sets')->to('ProblemSet#getAllUserSets');
	$course_routes->get('/sets/:set_id/users')->to('ProblemSet#getUserSets');
	$course_routes->post('/sets/:set_id/users')->to('ProblemSet#addUserSet');
	$course_routes->put('/sets/:set_id/users/:course_user_id')->to('ProblemSet#updateUserSet');
	$course_routes->delete('/sets/:set_id/users/:course_user_id')->to('ProblemSet#deleteUserSet');

	$course_routes->get('/users/:user_id/sets')->to('ProblemSet#getUserSets');
	return;
}

sub problemRoutes ($app, $course_routes) {
	$course_routes->get('/problems')->to('Problem#getAllProblems');
	$course_routes->get('/sets/:set_id/problems/:set_problem_id')->to('Problem#getProblem');
	$course_routes->post('/sets/:set_id/problems')->to('Problem#addProblem');
	$course_routes->put('/sets/:set_id/problems/:set_problem_id')->to('Problem#updateProblem');
	$course_routes->delete('/sets/:set_id/problems/:set_problem_id')->to('Problem#deleteProblem');

	# UserProblem routes
	$course_routes->get('/sets/:set_id/user-problems')->to('Problem#getUserProblemsForSet');
	$course_routes->get('/users/:user_id/problems')->to('Problem#getUserProblemsForUser');
	$course_routes->get('/sets/:set_id/users/:user_id/problems/:user_problem_id')->to('Problem#getUserProblem');
	$course_routes->post('/sets/:set_id/users/:user_id/problems')->to('Problem#addUserProblem');
	$course_routes->put('/sets/:set_id/users/:user_id/problems/:user_problem_id')->to('Problem#updateUserProblem');
	$course_routes->delete('/sets/:set_id/users/:user_id/problems/:user_problem_id')->to('Problem#deleteUserProblem');

	# ProblemPool Routes
	$course_routes->get('/pools')->to('Problem#getProblemPools');
	$course_routes->get('/pools/:problem_pool_id')->to('Problem#getProblemPool');
	$course_routes->post('/pools')->to('Problem#addProblemPool');
	$course_routes->put('/pools/:problem_pool_id')->to('Problem#updateProblemPool');
	$course_routes->delete('/pools/:problem_pool_id')->to('Problem#deleteProblemPool');

	# PoolProblem Routes

	# This gets all problems in a given pool
	$course_routes->get('/pools/:problem_pool_id/problems')->to('Problem#getPoolProblems');
	# This gets a random problem out of the given pool
	$course_routes->get('/pools/:problem_pool_id/problem')->to('Problem#getPoolProblem');
	# This gets the particular problem out of the given pool
	$course_routes->get('/pools/:problem_pool_id/problems/:pool_problem_id')->to('Problem#getPoolProblem');
	$course_routes->post('/pools/:problem_pool_id/problems')->to('Problem#addProblemToPool');
	$course_routes->put('/pools/:problem_pool_id/problems/:pool_problem_id')->to('Problem#updatePoolProblem');
	$course_routes->delete('/pools/:problem_pool_id/problems/:pool_problem_id')->to('Problem#removePoolProblem');
	return;
}

sub settingsRoutes ($self) {
	$self->routes->get('/webwork3/api/global-settings')->requires(authenticated => 1)->to('Settings#getGlobalSettings');
	$self->routes->get('/webwork3/api/global-setting/:setting_id')->requires(authenticated => 1)
		->to('Settings#getGlobalSetting');
	$self->routes->get('/webwork3/api/courses/:course_id/settings')->requires(authenticated => 1)
		->to('Settings#getCourseSettings');
	$self->routes->put('/webwork3/api/courses/:course_id/settings/:setting_id')->requires(authenticated => 1)
		->to('Settings#updateCourseSetting');
	$self->routes->delete('/webwork3/api/courses/:course_id/settings/:setting_id')->requires(authenticated => 1)
		->to('Settings#deleteCourseSetting');
	return;
}

sub utilityRoutes ($app) {
	$app->routes->post('/webwork3/api/client-logs')->requires(authenticated => 1)->to('Logger#clientLog');
	return;
}

1;
