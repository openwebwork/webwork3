package DB::Schema::Result::ProblemSet::Quiz;

use strict;
use warnings;
use feature 'signatures';
no warnings qw(experimental::signatures);

use base qw(DB::Schema::Result::ProblemSet DB::WithParams DB::WithDates);

=head1 DESCRIPTION

This is the database schema for a Quiz, a subclass of a C<DB::Schema::Result::ProblemSet>

In particular, this contains the methods C<valid_dates>, C<required_dates>,
C<valid_params> and C<required_params>.  See C<DB::Schema::Result::ProblemSet>
for details on these.

=cut

=head2 C<valid_dates>

subroutine that returns the array for the valid dates: C<['open', 'due' ,'answer']>

=cut

sub valid_dates ($=) {
	return [ 'open', 'due', 'answer' ];
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

C<timed> : boolean

whether or not the quiz should be a timed quiz

=item *

C<quiz_duration>: integer

if the quiz is timed, how long should it be open.

=item *

C<set_header>: string

The header information to the quiz.

=item *

C<hardcopy_header>: string

The header information to the quiz if printed.

=item *

C<problem_randorder>: boolean

If this is true, then the problems should be presented in a random order.

=item *

C<problems_per_page>: Non-negative integer

If value is 0, show all problems, else show this many per page.

=item *

C<hide_score>: string

(See Webwork2 ProblemSetDetail.pm -- stay with same options?)

=item *

C<hide_score_by_problem>: string

(See Webwork2 ProblemSetDetail.pm -- stay with same options?)

=item *

C<hide_work>: string

(See Webwork2 ProblemSetDetail.pm -- stay with same options?)

=item *

C<time_limit_cap>: boolean

If this is true, then cap the test time at due date.

=item *

C<restrict_ip>: string

(See Webwork2 ProblemSetDetail.pm -- stay with same options?)

=item *

C<relax_restrict_ip>: string

(See Webwork2 ProblemSetDetail.pm -- stay with same options?)




=back

=cut

sub valid_params ($=) {
	return {
		timed                 => q{^[01]$},
		quiz_duration         => q{\d+},
		set_header            => q{\w+},
		hardcopy_header       => q{\w+},
		problem_randorder     => q{^[01]$},
		problems_per_page     => q{\d+},
		hide_score            => q{\w+},
		hide_score_by_problem => q{\w+},
		hide_work             => q{\w+},
		time_limit_cap        => q{\d+},
		restrict_ip           => q{\w+},
		relax_restrict_ip     => q{\w+}
	};
}

=head2 C<required_params>

No parameters are required for the homework set.

=cut

sub required_params ($=) {
	return {};
}

1;
