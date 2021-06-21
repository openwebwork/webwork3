package webwork3;
use Mojo::Base 'Mojolicious', -signatures;

use Mojo::File qw(curfile);

my $webwork_root = curfile->dirname->sibling('lib')->to_string;

use Data::Dump qw/dd/;

use DB::Schema;


# This method will run once at server start
sub startup ($self) {

	# Load configuration from config file
	my $config = $self->plugin('NotYAMLConfig');

	# Configure the application
	$self->secrets($config->{secrets});

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

	$self->loginRoutes();
	$self->coursesRoutes();
	
}

sub load_account {
	my ($self,$user_id)  = @_;
	my $user = $self->schema->resultset("User")->getGlobalUser({email => $user_id});
	return $user->{user_id};
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




1;
