package WeBWorK3::Controller::Settings;
use warnings;
use strict;

=head1 Description

These are the methods that call the database for course settings

=cut

use Mojo::Base 'Mojolicious::Controller', -signatures;
use Mojo::File qw/path/;

use YAML::XS qw/LoadFile/;

# this reads the default settings from a file

sub getDefaultCourseSettings {
	my $self     = shift;
	my $settings = LoadFile(path($self->config->{webwork3_home}, "conf", "course_defaults.yml"));
	## check if the file exists
	$self->render(json => $settings);
	return;
}

sub getCourseSettings {
	my $self            = shift;
	my $course_settings = $self->schema->resultset("Course")->getCourseSettings({
		course_id => int($self->param("course_id")),
	});
	## flatten to a single array:
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
