package DB::Schema::Result::ProblemSet::ReviewSet;
use base qw/DB::Schema::Result::ProblemSet/;
use strict;
use warnings;

=head1 DESCRIPTION

This is the database schema for a Review Set, a subclass of a C<DB::Schema::Result::ProblemSet>

In particular, this contains the methods C<valid_dates>, C<required_dates>,
C<valid_params> and C<required_params>.  See C<DB::Schema::Result::ProblemSet>
for details on these.

=cut

=head2 C<valid_dates>

subroutine that returns the array for the valid dates: C<['open', 'closed']>

=cut

sub valid_dates {
	return ['open' ,'closed'];
}

=head2 C<required_dates>

subroutine that returns the array for the required dates: C<['open', 'closed']>

=cut

sub required_dates {
	return ['open' ,'closed'];
}

=head2 C<valid_params>

subroutine that returns the hashref for the valid parameters:  (currently empty)

=cut

sub valid_params {
	return {};
}

=head2 C<required_params>

subroutine that returns the hashref for the required parameters:  (currently empty)

=cut


sub required_params {
	return {};
}

1;
