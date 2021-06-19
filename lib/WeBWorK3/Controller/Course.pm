package webwork3::Controller::Course;
use Mojo::Base 'Mojolicious::Controller', -signatures;

use Data::Dump qw/dd/;

sub getCourses {
	my $self = shift; 
	$self->render(json => {msg => "hi"});
	my @all_courses =  $self->schema->resultset("Course")->getCourses; 
	$self->render(json => \@all_courses);
}

sub getCourse {
	my $self = shift; 
	my $course = $self->schema->resultset("Course")->getCourse( {course_id => int( $self->param("course_id") )} );
	$self->render(json => $course);
}

## update the course given by course_id with given params

sub updateCourse {
	my ($self,$course_params) = @_;
	my $course = $self->schema->resultset("Course")
		->updateCourse( {course_id => int( $self->param("course_id") )},$course_params);
	$self->render(json => $course);
}

sub addCourse {
	my ($self,$course_params) = @_;
	my $course = $self->schema->resultset("Course")
		->addCourse( {course_id => int( $self->param("course_id") )},$course_params);
	$self->render(json => $course);
}

1; 