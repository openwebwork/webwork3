use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

BEGIN {
	use File::Basename qw/dirname/;
	use Cwd qw/abs_path/;
	$main::test_dir = abs_path( dirname(__FILE__) );
	$main::lib_dir  = dirname( dirname($main::test_dir) ) . '/lib';
}

use lib "$main::lib_dir";

my $t = Test::Mojo->new('WeBWorK3');

# HTML/XML
$t->get_ok('/login')->status_is(200);

# $t->ua->max_redirects(1);

## test the redirect
$t->post_ok( '/login' => form => { login => 'lisa', password => 'lisa' } )->status_is(302)
	->header_is( location => '/users/start' );

$t->ua->max_redirects(1);
$t->post_ok( '/login' => form => { login => 'lisa', password => 'lisa' } )->status_is(200);

## test for a bad password
$t->ua->max_redirects(0);
$t->post_ok( '/login' => form => { login => 'lisa', password => 'wrong_password' } )->status_is(302)
	->header_is( location => '/login' );

$t->ua->max_redirects(1);
$t->post_ok( '/login' => form => { login => 'lisa', password => 'wrong_password' } )->status_is(200)
	->text_like( 'div#message' => qr!Incorrect username or password.! );

done_testing;
