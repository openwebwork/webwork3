#!/usr/bin/env perl

use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

BEGIN {
	use File::Basename qw/dirname/;
	use Cwd qw/abs_path/;
	$main::test_dir = abs_path(dirname(__FILE__));
	$main::lib_dir  = dirname(dirname($main::test_dir)) . '/lib';
}

use lib "$main::lib_dir";

my $t = Test::Mojo->new('WeBWorK3');

# Test missing credentials
$t->post_ok('/webwork3/api/login')->status_is(250, 'error status')->content_type_is('application/json;charset=UTF-8')
	->json_is(
	'' => {
		exception => 'DB::Exception::ParametersNeeded',
		message   => 'You must pass exactly one of user_id, username, email.'
	},
	'no credentials'
	);

# Test valid username and password
$t->post_ok('/webwork3/api/login' => json => { username => 'lisa', password => 'lisa' })->status_is(200)
	->content_type_is('application/json;charset=UTF-8')->json_is(
	'' => {
		logged_in => 1,
		user      => {
			email      => 'lisa@google.com',
			first_name => 'Lisa',
			is_admin   => 0,
			last_name  => 'Simpson',
			student_id => '23',
			user_id    => 3,
			username   => 'lisa'
		}
	},
	'valid credentials'
	);

# Test logout
$t->post_ok('/webwork3/api/logout')->status_is(200)->content_type_is('application/json;charset=UTF-8')->json_is(
	'' => {
		logged_in => 0,
		message   => 'Successfully logged out.'
	},
	'logout'
);

# Test for a bad password
$t->post_ok('/webwork3/api/login' => json => { username => 'lisa', password => 'wrong_password' })->status_is(200)
	->content_type_is('application/json;charset=UTF-8')->json_is(
	'' => {
		logged_in => 0,
		message   => 'Incorrect username or password.'
	},
	'invalid credentials'
	);

done_testing;
