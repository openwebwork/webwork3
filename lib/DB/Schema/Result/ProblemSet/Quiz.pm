package DB::Schema::Result::ProblemSet::Quiz;

use strict;
use warnings;
use base qw/DB::Schema::Result::ProblemSet/;

=head1 DESCRIPTION

This is the database schema for a Quiz, a subclass of a C<DB::Schema::Result::ProblemSet>

In particular, this contains the methods C<valid_dates>, C<required_dates>,
C<valid_params> and C<required_params>.  See C<DB::Schema::Result::ProblemSet>
for details on these.

=cut

=head2 C<valid_dates>

subroutine that returns the array for the valid dates: C<['open', 'due' ,'answer']>

=cut

sub valid_dates {
	return ['open', 'due' ,'answer'];
}

=head2 C<required_dates>

subroutine that returns the array for the required dates: C<['open', 'due' ,'answer']>

=cut


sub required_dates {
	return ['open', 'due' ,'answer'];
}

=head2 C<valid_params>

subroutine that returns the hashref for the valid params and their data types:

=over

=item *

C<timed> : boolean

whether or not the quiz should be a timed quiz

=item *

C<time_length>: integer

if the quiz is timed, how long should it be open.

=back

=cut

sub valid_params {
	return {
		timed => q{^[01]$},
		time_length => q{\d+},
	};
}

=head2 C<required_params>

No parameters are required for the homework set.

=cut


sub required_params {
	return {};
}

1;
