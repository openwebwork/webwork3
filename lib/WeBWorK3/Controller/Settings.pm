package WeBWorK3::Controller::Settings;

use warnings;
use strict;

use Mojo::JSON qw/true false/;
use DateTime::TimeZone;
use Try::Tiny;

=head1 Description

These are the methods that call the database for course settings

=cut

use Mojo::Base 'Mojolicious::Controller', -signatures;

sub getGlobalSettings ($c) {
	$c->render(json => $c->schema->resultset('Course')->getGlobalSettings());
	return;
}

sub getGlobalSetting ($c) {
	$c->render(
		json => $c->schema->resultset('Course')->getGlobalSetting(
			info => {
				global_setting_id => int($c->param('global_setting_id'))
			}
		)
	);
	return;
}

sub getCourseSettings ($c) {
	$c->render(
		json => $c->schema->resultset('Course')->getCourseSettings(
			info => {
				course_id => int($c->param('course_id')),
			},
			merged => 1
		)
	);
	return;
}

sub getCourseSetting ($c) {
	$c->render(
		json => $c->schema->resultset('Course')->getCourseSetting(
			info => {
				course_id         => int($c->param('course_id')),
				global_setting_id => int($c->param('global_setting_id'))
			}
		)
	);
	return;
}

sub updateCourseSetting ($c) {
	$c->render(
		json => $c->schema->resultset('Course')->updateCourseSetting(
			info => {
				course_id         => $c->param('course_id'),
				global_setting_id => $c->param('global_setting_id')
			},
			params => $c->req->json
		)
	);
	return;
}

sub deleteCourseSetting ($c) {
	$c->schema->resultset('Course')->deleteCourseSetting(
		info => {
			course_id         => $c->param('course_id'),
			global_setting_id => $c->param('global_setting_id')
		}
	);
	$c->render(json => { message => 'The course setting was successfully deleted.' });
	return;
}

# This is useful for checking if the string passed in is a valid timezone, instead of
# having the UI download all possible timezones (bloated).

sub checkTimeZone ($c) {
	try {
		DateTime::TimeZone->new(name => $c->req->json->{timezone});
		$c->render(json => { valid_timezone => true });
	} catch {
		$c->render(json => { valid_timezone => false });
	};
	return;
}

1;
