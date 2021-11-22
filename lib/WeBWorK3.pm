package WeBWorK3;
use Mojo::Base 'Mojolicious', -signatures;

use Mojo::File qw(curfile path);
use YAML::XS qw/LoadFile/;

BEGIN {
	## no critic (RequireLocalizedPunctuationVars)
	$ENV{WW3_ROOT} = curfile->dirname->dirname->to_string;
}

use DB::Schema;
use WeBWorK3::Hooks;

my $perm_table;

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
			schema =>
				DB::Schema->connect($config->{database_dsn}, $config->{database_user}, $config->{database_password})
		}
	);

	# Load the authentication plugin
	$self->plugin(
		Authentication => {
			load_user     => sub ($app, $uid) { $self->load_account($uid) },
			validate_user => sub ($c,   $u, $p, $e) { $self->validate($u, $p) ? $u : undef; }
		}
	);

	# Set up the session
	$self->sessions->cookie_name('Webwork3Authen');
	$self->sessions->default_expiration($config->{cookie_lifetime});
	$self->sessions->cookie_path('/webwork3');
	$self->sessions->samesite($config->{cookie_samesite});
	$self->sessions->secure($config->{cookie_secure});

	# Load permissions and set up some helpers for dealing with permissions.
	$perm_table = LoadFile("$ENV{WW3_ROOT}/conf/permissions.yaml");

	$self->helper(perm_table         => sub ($c) { return $perm_table; });
	$self->helper(ignore_permissions => sub ($c) { return $config->{ignore_permissions}; });

	# Handle all api route exceptions
	$self->hook(around_dispatch => $WeBWorK3::Hooks::exception_handler);

	$self->hook(around_action => $WeBWorK3::Hooks::check_permission);

	# Load all routes
	$self->loginRoutes();
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
	my $user = $self->schema->resultset("User")->getGlobalUser({ username => $user_id });
	return $user;
}

sub validate ($self, $user, $password) {
	return $self->schema->resultset("User")->authenticate($user, $password);
}

sub loginRoutes ($self) {
	$self->routes->post('/webwork3/api/login')->to('Login#login');
	$self->routes->any('/webwork3/api/logout')->to('Login#logout_user');
	return;
}

sub coursesRoutes ($self) {
	my $course_routes = $self->routes->any('/webwork3/api/courses')->to(controller => 'Course');
	$course_routes->get('/')->to(action => 'getCourses');
	$course_routes->get('/:course_id')->to(action => 'getCourse');
	$course_routes->put('/:course_id')->to(action => 'updateCourse');
	$course_routes->post('/')->to(action => 'addCourse');
	$course_routes->delete('/:course_id')->to(action => 'deleteCourse');
	return;
}

sub userRoutes ($self) {
	my $user_routes = $self->routes->any('/webwork3/api/users')->to(controller => 'User');
	$user_routes->get('/')->to(action => 'getGlobalUsers');
	$user_routes->post('/')->to(action => 'addGlobalUser');
	$user_routes->get('/:user')->to(action => 'getGlobalUser');
	$user_routes->put('/:user_id')->to(action => 'updateGlobalUser');
	$user_routes->delete('/:user_id')->to(action => 'deleteGlobalUser');
	$user_routes->get('/:user_id/courses')->to(action => 'getUserCourses');
	return;
}

sub courseUserRoutes ($self) {
	my $course_user_routes = $self->routes->any('/webwork3/api/courses/:course_id/users')->to(controller => 'User');
	$course_user_routes->get('/')->to(action => 'getCourseUsers');
	$course_user_routes->post('/')->to(action => 'addCourseUser');
	$course_user_routes->get('/:user_id')->to(action => 'getCourseUser');
	$course_user_routes->put('/:user_id')->to(action => 'updateCourseUser');
	$course_user_routes->delete('/:user_id')->to(action => 'deleteCourseUser');
	$self->routes->any('/webwork3/api/courses/:course_id/courseusers')->to('User#getMergedCourseUsers');
	return;
}

sub problemSetRoutes ($self) {
	$self->routes->get('/webwork3/api/sets')->to("ProblemSet#getProblemSets");
	my $problem_set_routes =
		$self->routes->any('/webwork3/api/courses/:course_id/sets')->to(controller => 'ProblemSet');
	$problem_set_routes->get('/')->to(action => 'getProblemSets');
	$problem_set_routes->get('/:set_id')->to(action => 'getProblemSet');
	$problem_set_routes->put('/:set_id')->to(action => 'updateProblemSet');
	$problem_set_routes->post('/')->to(action => 'addProblemSet');
	$problem_set_routes->delete('/:set_id')->to(action => 'deleteProblemSet');
	$problem_set_routes->get('/:set_id/users')->to(action => 'getUserSets');
	$problem_set_routes->post('/:set_id/users')->to(action => 'addUserSet');
	$problem_set_routes->put('/:set_id/users/:course_user_id')->to(action => 'updateUserSet');
	$problem_set_routes->delete('/:set_id/users/:course_user_id')->to(action => 'deleteUserSet');
	return;
}

sub problemRoutes ($self) {
	my $problem_routes = $self->routes->any('/webwork3/api/courses/:course_id')->to(controller => 'Problem');
	$problem_routes->get('/problems')->to(action => 'getAllProblems');
	$problem_routes->post('/sets/:set_id/problems')->to(action => 'addProblem');
	$problem_routes->put('/sets/:set_id/problems/:problem_id')->to(action => 'updateProblem');
	$problem_routes->delete('/sets/:set_id/problems/:problem_id')->to(action => 'deleteProblem');

	return;
}

sub settingsRoutes ($self) {
	$self->routes->get('/webwork3/api/default_settings')->to("Settings#getDefaultCourseSettings");
	$self->routes->get('/webwork3/api/courses/:course_id/settings')->to("Settings#getCourseSettings");
	return;
}

sub utilityRoutes ($self) {
	$self->routes->post('/webwork3/api/client-logs')->to("Logger#clientLog");
	return;
}

1;
