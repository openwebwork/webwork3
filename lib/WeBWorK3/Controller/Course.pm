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

1; 