package DB::Schema::Result::ProblemSet::HWSet;

use strict;
use warnings;
use feature 'signatures';
no warnings qw(experimental::signatures);

use base qw(DB::Schema::Result::ProblemSet DB::WithParams DB::WithDates);

=head1 DESCRIPTION

This is the database schema for a HWSet, a subclass of a C<DB::Schema::Result::ProblemSet>

In particular, this contains the methods C<valid_dates>, C<required_dates>,
C<valid_params> and C<required_params>.  See C<DB::Schema::Result::ProblemSet>
for details on these.

=cut

=head2 C<valid_dates>

subroutine that returns the array for the valid dates: C<['open', 'reduced_scoring', 'due' ,'answer']>

=cut

sub valid_dates ($=) {
	return [ 'open', 'reduced_scoring', 'due', 'answer' ];
}

sub optional_fields_in_dates ($=) {
	return ['enable_reduced_scoring'];
}

=head2 C<required_dates>

subroutine that returns the array for the required dates: C<['open', 'due' ,'answer']>

=cut

sub required_dates ($=) {
	return [ 'open', 'due', 'answer' ];
}

=head2 C<valid_params>

subroutine that returns the hashref for the valid params and their data types:

=over

=item *

C<enable_reduced_scoring> : boolean

This determines if the homework set allows a reduced scoring period.

=item *

C<hide_hint> : boolean

This determines if the homework set hides hints to students.

=item *

C<hardcopy_header> : string

This is the header to the homework set when a hardcopy (PDF) is generated.

=item *

C<set_header> : string

This is the header to the homework set.

=item *

C<description> : string

This is a description of the homework set.

=back

=cut

sub valid_params ($=) {
	return {
		enable_reduced_scoring => 'bool',
		hide_hint              => 'bool',
		hardcopy_header        => q{.*},
		set_header             => q{.*},
		description            => q{.*}
	};
}

=head2 C<required_params>

No parameters are required for the homework set.

=cut

sub required_params ($=) {
	return {};
}

1;
