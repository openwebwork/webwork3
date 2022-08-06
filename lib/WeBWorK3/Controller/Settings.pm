package WeBWorK3::Controller::Settings;

use warnings;
use strict;

=head1 Description

These are the methods that call the database for course settings

=cut

use Mojo::Base 'Mojolicious::Controller', -signatures;

sub getGlobalSettings ($c) {
	my $settings = $c->schema->resultset('Course')->getGlobalSettings();
	$c->render(json => $settings);
	return;
}

sub getGlobalSetting ($c) {
	my $setting = $c->schema->resultset('Course')->getGlobalSetting(info => {
		setting_id => int($c->param('setting_id'))
	});
	$c->render(json => $setting);
	return;
}

sub getCourseSettings ($c) {
	my $course_settings = $c->schema->resultset('Course')->getCourseSettings(
		info => {
			course_id => int($c->param('course_id')),
		},
		merged => 1
	);
	$c->render(json => $course_settings);
	return;
}

sub updateCourseSetting ($c) {
	my $course_setting = $c->schema->resultset('Course')->updateCourseSetting(
		info     => {
			course_id => $c->param('course_id'),
			setting_id => $c->param('setting_id')
		},
		params => $c->req->json
	);
	$c->render(json => $course_setting);
	return;
}

sub deleteCourseSetting ($c) {
	my $course_setting = $c->schema->resultset('Course')->deleteCourseSetting(
		info     => {
			course_id => $c->param('course_id'),
			setting_id => $c->param('setting_id')
		});
	$c->render(json => $course_setting);
	return;
}


1;
