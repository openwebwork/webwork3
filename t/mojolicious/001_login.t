#!/usr/bin/env perl

use Mojo::Base -strict;

use Test2::V0;
use Test2::MojoX;
use YAML::XS qw/LoadFile/;
use Mojo::JSON qw/true false/;

BEGIN {
	use File::Basename qw/dirname/;
	use Cwd qw/abs_path/;
	$main::ww3_dir = abs_path(dirname(__FILE__)) . '/../..';
}

use lib "$main::ww3_dir/lib";

# Load the config file.
my $config_file = "$main::ww3_dir/conf/webwork3-test.yml";
$config_file = "$main::ww3_dir/conf/webwork3-test.dist.yml" unless (-e $config_file);

my $t = Test2::MojoX->new('WeBWorK3' => LoadFile($config_file));

# Test missing credentials
$t->post_ok('/webwork3/api/login')->status_is(500, 'error status')->content_type_is('application/json;charset=UTF-8')
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
			logged_in => true,
			user      => {
				email      => 'lisa@google.com',
				first_name => 'Lisa',
				is_admin   => false,
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
		logged_in => false,
		message   => 'Successfully logged out.'
	},
	'logout'
);

# Test for a bad password
$t->post_ok('/webwork3/api/login' => json => { username => 'lisa', password => 'wrong_password' })->status_is(200)
	->content_type_is('application/json;charset=UTF-8')->json_is(
		'' => {
			logged_in => false,
			message   => 'Incorrect username or password.'
		},
		'invalid credentials'
	);

done_testing;
