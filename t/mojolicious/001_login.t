#!/usr/bin/env perl

use Test2::V0;
use Mojo::Base -signatures;
use Test2::MojoX;
use Mojo::File qw/curfile/;
use Mojo::JSON qw/true false/;

use lib curfile->dirname->dirname->sibling('lib')->to_string;
use lib curfile->dirname->sibling('lib')->to_string;

use DBSubtest qw/mojoDBSubtest/;

mojoDBSubtest 'login routes' => sub ($t, $schema) {
	# Deploy the database.
	$schema->deploy({ add_drop_table => 1 });

	# Add the user for the test.
	$schema->resultset('User')->create({
		email        => 'lisa@google.com',
		first_name   => 'Lisa',
		is_admin     => false,
		last_name    => 'Simpson',
		student_id   => '23',
		user_id      => 3,
		username     => 'lisa',
		login_params => { password => 'lisa' }
	});

	# Test missing credentials
	$t->post_ok('/webwork3/api/login')->status_is(500, 'error status')
		->content_type_is('application/json;charset=UTF-8')->json_is(
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
	$t->post_ok('/webwork3/api/logout')->status_is(200)->content_type_is('application/json;charset=UTF-8')
		->json_is('' => { logged_in => false, message => 'Successfully logged out.' }, 'logout');

	# Test for a bad password
	$t->post_ok('/webwork3/api/login' => json => { username => 'lisa', password => 'wrong_password' })
		->status_is(200)->content_type_is('application/json;charset=UTF-8')->json_is(
			'' => { logged_in => false, message => 'Incorrect username or password.' },
			'invalid credentials'
		);
};

done_testing;
