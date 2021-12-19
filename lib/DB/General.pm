package DB::General;
use strict;
use warnings;

=head1 description

The class DB::Schema::ResultSet::General pull the common functionality for
the other classes in the schema resultsets include

=over

=item Course

=item User

=item ProblemSet

=item UserSet

=item Problem

=back

=cut

use Carp;
use List::Util qw/first/;

use Clone qw/clone/;
use DB::Utils qw/getCourseInfo getUserInfo/;
use DB::Exception;
use Exception::Class ('DB::Exception::CourseNotFound', 'DB::Exception::CourseExists');

use DB::TestUtils qw/removeIDs/;
use WeBWorK3::Utils::Settings qw/getDefaultCourseSettings mergeCourseSettings
	getDefaultCourseValues validateCourseSettings/;

1;
