package WeBWorK3;
use Mojo::Base 'Mojolicious', -signatures;

use Mojo::File qw(curfile);
use YAML::XS qw/LoadFile/;

my $webwork_root;
BEGIN {
	$webwork_root = curfile->dirname->to_string . "/..";
}

use Data::Dump qw/dd/;
use Try::Tiny;

use DB::Schema;
use WeBWorK3::Mojolicious;

# require Exporter;
# use base qw(Exporter);
# our @EXPORT_OK = qw/confDirectory/;

my $perm_table;

# This method will run once at server start
sub startup {
	my $self = shift;
	# Load configuration from config file
	my $config = $self->plugin('NotYAMLConfig');

	# Configure the application
	$self->secrets($config->{secrets});
	## get the dbix plugin loaded

	my $schema = DB::Schema->connect("dbi:SQLite:dbname=$webwork_root/t/db/sample_db.sqlite");
	$self->plugin('DBIC',{schema => $schema});

	# load the authentication plugin
	$self->plugin(
		Authentication => {
				load_user     => sub ($app, $uid) { $self->load_account($uid) },
				validate_user => sub ($c, $u, $p, $e) { $self->validate($u, $p) ? $u : () },
		}
	);

	$self->helper( perm_table => sub ($c) {
		$perm_table = LoadFile("$webwork_root/conf/permissions.yaml") unless defined($perm_table);
		return $perm_table;
	});

	$self->helper( ignore_permissions => sub ($c) { return $config->{ignore_permissions}; });

	## handle all api route exceptions

	$self->hook( around_dispatch => $WeBWorK3::Mojolicious::exception_handler );
	$self->hook( around_action   => $WeBWorK3::Mojolicious::check_permission );

	## load all routes
	$self->loginRoutes();
	$self->coursesRoutes();
	$self->userRoutes();
	$self->courseUserRoutes();
	$self->problemSetRoutes();
	return;
}

sub confDirectory {
	return "$webwork_root/conf";
}


sub load_account {
	my ($self,$user_id)  = @_;
	my $user = $self->schema->resultset("User")->getGlobalUser({email => $user_id});
	return $user;
}

sub validate {
	my ($self,$user,$password) = @_;
	return $self->schema->resultset("User")->authenticate($user,$password);
}

sub loginRoutes {
	my $self = shift;

	# Normal route to controller
	$self->routes->get('/login')->to('Login#login_page');
	$self->routes->get('/login/help')->to('Login#login_help');
	$self->routes->get('/users/start')->to('Login#user_courses');
	$self->routes->post('/login')->to('Login#check_login');
	$self->routes->get('/logout')->to('Login#logout_page');
	$self->routes->post('/webwork3/api/login')->to('Login#login');
	$self->routes->any('/webwork3/api/logout')->to('Login#logout_user');
	return;
}

sub coursesRoutes {
	my $self = shift;
	my $course_routes = $self->routes->any('/webwork3/api/courses')->to(controller => 'Course');
	$course_routes->get('/')->to(action => 'getCourses');
	$course_routes->get('/:course_id')->to(action => 'getCourse');
  $course_routes->put('/:course_id')->to(action => 'updateCourse');
	$course_routes->post('/')->to(action => 'addCourse');
	$course_routes->delete('/:course_id')->to(action => 'deleteCourse');
	return;
}

sub userRoutes {
	my $self = shift;
	my $course_routes = $self->routes->any('/webwork3/api/users')->to(controller => 'User');
	$course_routes->get('/')->to(action => 'getGlobalUsers');
	$course_routes->post('/')->to(action => 'addGlobalUser');
	$course_routes->get('/:user_id')->to(action => 'getGlobalUser');
	$course_routes->put('/:user_id')->to(action => 'updateGlobalUser');
	$course_routes->delete('/:user_id')->to(action => 'deleteGlobalUser');
	$self->routes->get('/webwork3/api/users/:user_id/courses')->to('User#getUserCourses');
	return;
}

sub courseUserRoutes {
	my $self = shift;
	my $course_user_routes = $self->routes->any('/webwork3/api/courses/:course_id/users')->to(controller =>'User');
	$course_user_routes->get('/')->to(action => 'getUsers');
	$course_user_routes->post('/')->to(action => 'addUser');
	$course_user_routes->get('/:user_id')->to(action => 'getUser');
	$course_user_routes->put('/:user_id')->to(action => 'updateUser');
	$course_user_routes->delete('/:user_id')->to(action => 'deleteUser');
	return;
}

sub problemSetRoutes {
	my $self = shift;
	$self->routes->get('/webwork3/api/sets')->to("ProblemSet#getProblemSets");
	my $course_routes = $self->routes->any('/webwork3/api/courses/:course_id/sets')->to(controller => 'ProblemSet');
	$course_routes->get('/')->to(action => 'getProblemSets');
	$course_routes->get('/:set_id')->to(action => 'getProblemSet');
  $course_routes->put('/:set_id')->to(action => 'updateProblemSet');
	$course_routes->post('/')->to(action => 'addProblemSet');
	$course_routes->delete('/:set_id')->to(action => 'deleteProblemSet');
	return;
}


1;
