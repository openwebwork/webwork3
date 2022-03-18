package DB::Schema::Result::UserSet::HWSet;
use DB::WithParams;
use DB::WithDates;

use strict;
use warnings;
use base qw(DB::Schema::Result::UserSet DB::WithParams DB::WithDates);

use DB::Schema::Result::ProblemSet::HWSet;

=head1 DESCRIPTION

This is the database schema for a UserSet version HWSet, a subclass of a C<DB::Schema::Result::UserSet>

In particular, this contains the methods C<valid_dates>, C<required_dates>,
C<valid_params> and C<required_params>.  See C<DB::Schema::Result::ProblemSet>
for details on these.

=cut

=head2 C<valid_dates>

subroutine that returns the array for the valid dates: C<['open', 'reduced_scoring', 'due' ,'answer']>

=cut

sub valid_dates {
	return [ 'open', 'reduced_scoring', 'due', 'answer' ];
}

=head2 C<required_dates>

subroutine that returns the array for the required dates: C<['open', 'due' ,'answer']>

=cut

sub required_dates {
	return [];
}

sub valid_params {
	return {
		enable_reduced_scoring => q{[01]},
		hide_hint              => q{[01]},
		hardcopy_header        => q{.*},
		set_header             => q{.*},
		description            => q{.*}
	};
}

=head2 C<required_params>

No parameters are required for the homework set.

=cut

sub required_params {
	return {};
}

1;
