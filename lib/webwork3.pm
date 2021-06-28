package webwork3;
use Mojo::Base 'Mojolicious', -signatures;

use Mojo::File qw(curfile);
use YAML::XS qw/LoadFile/;

my $webwork_root = curfile->dirname->sibling('lib')->to_string;

use Data::Dump qw/dd/;
use Try::Tiny;

use DB::Schema;

## perhaps make this a plugin

my $handle_exception = sub ($next, $c) {
	## only test requests that start with "/api"
	# dd "in handle_exception";
	if ($c->req->url->to_string =~ /\/api/) {
		try {
			$next->();
		} catch {
			$c->render(json => {msg => "oops!", message=> $_->message, exception => ref($_)});
		};
	} else {
		$next->();
	}
};

my $ignore_permissions = 1;
my $perm_table = LoadFile("$webwork_root/../conf/permissions.yaml");

sub has_permission {
  my ($user,$controller_name, $action_name) = @_;
	dd "in has_permission";
	my $perm = $perm_table->{$controller_name}->{$action_name};
	return 1 unless $perm->{check_permission};
	return $user->{is_admin} if $perm->{admin_required};
	## check non-admin routes;

	return 1;
}

## check permission for /api routes

my $check_permission = sub {
	my ($next, $c, $action, $last) = @_;
	dd "in check_permission";
	# dd $c->{stash};
	return $next->() if ($c->req->url->to_string =~ /\/api\/login/);
	if ($c->req->url->to_string =~ /\/api/) {
		dd has_permission($c->current_user,$c->{stash}->{controller},$c->{stash}->{action});
		if (has_permission($c->current_user,$c->{stash}->{controller},$c->{stash}->{action})) {
			return $next->();
		} else {
			$c->render( json => { has_permission => 0, msg => "permission error"});
		}
	} else {
		$next->();
	}
};

# This method will run once at server start
sub startup ($self) {

	# Load configuration from config file
	my $config = $self->plugin('NotYAMLConfig');

	# Configure the application
	$self->secrets($config->{secrets});
	$ignore_permissions = $config->{ignore_permissions};
	## get the dbix plugin loaded

	my $schema = DB::Schema->connect("dbi:SQLite:dbname=$webwork_root/../t/db/sample_db.sqlite");

	$self->plugin('DBIC',{schema => $schema});

	# load the authentication plugin

	$self->plugin(
		Authentication => {
				load_user     => sub ($app, $uid) { $self->load_account($uid) },
				validate_user => sub ($c, $u, $p, $e) { $self->validate($u, $p) ? $u : () },
		}
	);





	## handle all api route exceptions
	$self->hook( around_dispatch => $handle_exception);
	$self->hook( around_action => $check_permission);

	## load all routes
	$self->loginRoutes();
	$self->coursesRoutes();
	$self->userRoutes();
	$self->courseUserRoutes();
	$self->problemSetRoutes();

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
	$self->routes->post('/api/login')->to('Login#login');
	$self->routes->any('/api/logout')->to('Login#logout_user');
}

sub coursesRoutes {
	my $self = shift;
	my $course_routes = $self->routes->any('/api/courses')->to(controller => 'Course');
	$course_routes->get('/')->to(action => 'getCourses');
	$course_routes->get('/:course_id')->to(action => 'getCourse');
  $course_routes->put('/:course_id')->to(action => 'updateCourse');
	$course_routes->post('/')->to(action => 'addCourse');
	$course_routes->delete('/:course_id')->to(action => 'deleteCourse');
}

sub userRoutes {
	my $self = shift;
	my $course_routes = $self->routes->any('/api/users')->to(controller => 'User');
	$course_routes->get('/')->to(action => 'getGlobalUsers');
	$course_routes->post('/')->to(action => 'addGlobalUser');
	$course_routes->get('/:user_id')->to(action => 'getGlobalUser');
	$course_routes->put('/:user_id')->to(action => 'updateGlobalUser');
	$course_routes->delete('/:user_id')->to(action => 'deleteGlobalUser');
}

sub courseUserRoutes {
	my $self = shift;
	my $course_user_routes = $self->routes->any('/api/courses/:course_id/users')->to(controller =>'User');
	$course_user_routes->get('/')->to(action => 'getUsers');
	$course_user_routes->post('/')->to(action => 'addUser');
	$course_user_routes->get('/:user_id')->to(action => 'getUser');
	$course_user_routes->put('/:user_id')->to(action => 'updateUser');
	$course_user_routes->delete('/:user_id')->to(action => 'deleteUser');

}

sub problemSetRoutes {
	my $self = shift;
	$self->routes->get('/api/sets')->to("ProblemSet#getProblemSets");
	my $course_routes = $self->routes->any('/api/courses/:course_id/sets')->to(controller => 'ProblemSet');
	$course_routes->get('/')->to(action => 'getProblemSets');
	$course_routes->get('/:set_id')->to(action => 'getProblemSet');
  $course_routes->put('/:set_id')->to(action => 'updateProblemSet');
	$course_routes->post('/')->to(action => 'addProblemSet');
	$course_routes->delete('/:set_id')->to(action => 'deleteProblemSet');
}


1;
