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

	# Router
	my $r = $self->routes;
	$self->loginRoutes();

	$r->get('/courses')->to({controller => 'Course', action => 'getCourses'});
	$r->get('/courses/:course_id')->to({controller => 'Course', action => 'getCourse'});

}

sub load_account {
	my ($self,$user_id)  = @_;
	dd "in load_account";
	my $user = $self->schema->resultset("User")->getGlobalUser({email => $user_id});
	return $user->{user_id};
}

sub validate {
	my ($self,$user,$password) = @_;
	dd "in validate";
	dd "user: $user   password: $password";
	return $self->schema->resultset("User")->authenticate($user,$password);
}

sub loginRoutes {
	my $self = shift; 
	
	# Normal route to controller
	$self->routes->get('/')->to('Example#welcome');
	$self->routes->get('/login')->to('Login#login_page');
	$self->routes->get('/users/:user_id')->to('Login#user_courses');
	$self->routes->post('/login')->to('Login#check_login');

}




1;
