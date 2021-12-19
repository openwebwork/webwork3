package WeBWorK3::Controller::Course;
use warnings;
use strict;

use Mojo::Base 'Mojolicious::Controller', -signatures;

sub getCourses {
	my $self        = shift;
	my @all_courses = $self->schema->resultset("Course")->getCourses;
	$self->render(json => \@all_courses);
	return;
}

sub getCourse {
	my $self   = shift;
	my $course = $self->schema->resultset("Course")->getCourse({ course_id => int($self->param("course_id")) });
	$self->render(json => $course);
	return;
}

## update the course given by course_id with given params

sub updateCourse {
	my $self   = shift;
	my $course = $self->schema->resultset("Course")
		->updateCourse({ course_id => int($self->param("course_id")) }, $self->req->json);
	$self->render(json => $course);
	return;
}

sub addCourse {
	my $self   = shift;
	my $course = $self->schema->resultset("Course")->addCourse($self->req->json);
	$self->render(json => $course);
	return;
}

sub deleteCourse {
	my $self   = shift;
	my $course = $self->schema->resultset("Course")->deleteCourse({ course_id => int($self->param("course_id")) });
	$self->render(json => $course);
	return;
}

1;
