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

sub getDefaultCourseSettings ($self) {
	my $settings = LoadFile(path($self->config->{webwork3_home}, "conf", "course_defaults.yml"));
	# Check if the file exists.
	$self->render(json => $settings);
	return;
}

sub getCourseSettings ($self) {
	my $course_settings = $self->schema->resultset("Course")->getCourseSettings(
		info => {
			course_id => int($self->param("course_id")),
		}
	);
	# Flatten to a single array.
	my @course_settings = ();
	for my $category (keys %$course_settings) {
		for my $key (keys %{ $course_settings->{$category} }) {
			push(@course_settings, { var => $key, value => $course_settings->{$category}->{$key} });
		}
	}
	$self->render(json => \@course_settings);
	return;
}

1;
