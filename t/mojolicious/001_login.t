#!/usr/bin/env perl

use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use YAML::XS qw/LoadFile/;

BEGIN {
	use File::Basename qw/dirname/;
	use Cwd qw/abs_path/;
	$main::ww3_dir = abs_path(dirname(__FILE__)) . '/../..';
}

use lib "$main::ww3_dir/lib";

my $config_file = "$main::ww3_dir/conf/ww3-dev.yml";
die "The file $config_file does not exist.  Did you make a copy of it from ww3-dev.dist.yml ?"
	unless (-e $config_file);

my $config = LoadFile($config_file);

my $t = Test::Mojo->new(WeBWorK3 => $config);

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
