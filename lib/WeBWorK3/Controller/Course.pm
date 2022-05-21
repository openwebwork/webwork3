package WeBWorK3::Controller::Course;
use warnings;
use strict;

use Mojo::Base 'Mojolicious::Controller', -signatures;

sub getCourses ($self) {
	my @all_courses = $self->schema->resultset("Course")->getCourses;
	$self->render(json => \@all_courses);
	return;
}

sub getCourse ($self) {
	my $course = $self->schema->resultset("Course")->getCourse(info => { course_id => int($self->param("course_id")) });
	$self->render(json => $course);
	return;
}

# Update the course given by course_id with given params.

sub updateCourse ($self) {
	my $course = $self->schema->resultset("Course")->updateCourse(
		info => {
			course_id => int($self->param("course_id"))
		},
		params => $self->req->json
	);
	$self->render(json => $course);
	return;
}

sub addCourse ($self) {
	my $course = $self->schema->resultset("Course")->addCourse(params => $self->req->json);
	$self->render(json => $course);
	return;
}

sub deleteCourse ($self) {
	my $course =
		$self->schema->resultset("Course")->deleteCourse(info => { course_id => int($self->param("course_id")) });
	$self->render(json => $course);
	return;
}

1;
