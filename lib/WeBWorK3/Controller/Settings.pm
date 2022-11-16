package WeBWorK3::Controller::Settings;

use warnings;
use strict;

=head1 Description

These are the methods that call the database for course settings

=cut

use Mojo::Base 'Mojolicious::Controller', -signatures;
use Mojo::File qw/path/;

use YAML::XS qw/LoadFile/;

# This reads the default settings from a file.

sub getDefaultCourseSettings ($c) {
	my $settings = LoadFile($c->app->home->child('conf', 'course_defaults.yml'));
	# Check if the file exists.
	$c->render(json => $settings);
	return;
}

sub getCourseSettings ($c) {
	my $course_settings = $c->schema->resultset('Course')->getCourseSettings(
		info => {
			course_id => int($c->param('course_id')),
		}
	);
	# Flatten to a single array.
	my @course_settings = ();
	for my $category (keys %$course_settings) {
		for my $key (keys %{ $course_settings->{$category} }) {
			push(@course_settings, { var => $key, value => $course_settings->{$category}->{$key} });
		}
	}
	$c->render(json => \@course_settings);
	return;
}

sub updateCourseSetting ($c) {
	my $course_setting =
		$c->schema->resultset('Course')->updateCourseSettings({ course_id => $c->param('course_id') }, $c->req->json);
	$c->render(json => $course_setting);
	return;
}

1;
