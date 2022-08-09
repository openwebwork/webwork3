package WeBWorK3::Controller::Course;
use warnings;
use strict;

use Mojo::Base 'Mojolicious::Controller', -signatures;

sub getCourses ($c) {
	my @all_courses = $c->schema->resultset('Course')->getCourses;
	$c->render(json => \@all_courses);
	return;
}

sub getCourse ($c) {
	my $course = $c->schema->resultset('Course')->getCourse(info => { course_id => int($c->param('course_id')) });
	$c->render(json => $course);
	return;
}

# Update the course given by course_id with given params.

sub updateCourse ($c) {
	my $course = $c->schema->resultset('Course')
		->updateCourse(info => { course_id => int($c->param('course_id')) }, params => $c->req->json);
	$c->render(json => $course);
	return;
}

sub addCourse ($c) {
	my $course = $c->schema->resultset('Course')->addCourse(params => $c->req->json);
	$c->render(json => $course);
	return;
}

sub deleteCourse ($c) {
	my $course =
		$c->schema->resultset('Course')->deleteCourse(info => { course_id => int($c->param('course_id')) });
	$c->render(json => $course);
	return;
}

1;
