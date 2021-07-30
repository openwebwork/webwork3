package DB::General;
use strict;
use warnings;

=pod

=head1 description

The class DB::Schema::ResultSet::General pull the common functionality for
the other classes in the schema resultsets include

=item Course
=item User
=item ProblemSet
=item UserSet
=item Problem

=cut

use Carp;
use Data::Dump qw/dd dump/;
use List::Util qw/first/;

use Clone qw/clone/;
use DB::Utils qw/getCourseInfo getUserInfo/;
use DB::Exception;
use Exception::Class ( 'DB::Exception::CourseNotFound', 'DB::Exception::CourseExists' );

use DB::TestUtils qw/removeIDs/;
use WeBWorK3::Utils::Settings qw/getDefaultCourseSettings mergeCourseSettings
	getDefaultCourseValues validateCourseSettings/;





