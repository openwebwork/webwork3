package WeBWorK3::Controller::Course;
use Mojo::Base 'Mojolicious::Controller', -signatures;

use Data::Dump qw/dd/;

sub getCourses($self) {
	my @all_courses =  $self->courses->getCourses; 
	$self->render(json => \@all_courses);
}

sub getCourse($self) {

	my $course = $self->param("course_id") =~ /^\d+/ ? 
			$self->courses->getCourseByID( int( $self->param("course_id"))):
			$self->courses->getCourseByName($self->param("course_id"));

	$self->render(json => $course);
}

1; 