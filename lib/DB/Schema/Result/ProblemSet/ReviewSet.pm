package DB::Schema::Result::ProblemSet::ReviewSet;

use strict;
use warnings;
use feature 'signatures';
no warnings qw/experimental::signatures/;

use base qw(DB::Schema::Result::ProblemSet DB::Validation);

=head1 DESCRIPTION

This is the database schema for a Review Set, a subclass of a C<DB::Schema::Result::ProblemSet>

In particular, this contains the methods C<valid_fields>, C<required>,
and C<additional_validation>.  See C<DB::Validation>
for details on these.

=cut

=head2 C<valid_fields>

subroutine that returns a hash of the validation for both set_dates and set_params.

=cut

sub valid_fields ($self, %args) {
	if ($args{field_name} eq 'set_dates') {
		return {
			open => q{\d+},
			closed => q{\d+},
		};
	} elsif ($args{field_name} eq 'set_params') {
		return {
			can_retake => 'bool',
		}
	} else {
		return {};
	}
}

=head2 C<additional_validation>

subroutine that checks any additional validation

=cut

sub additional_validation ($self, %args) {
	return 1 if ($args{field_name} ne 'set_dates');

	my $dates = $self->get_inflated_column('set_dates');
	DB::Exception::ImproperDateOrder->throw(message => 'The dates are not in order')
		unless $dates->{open} <= $dates->{closed};
	
	return 1;
}

=head2 C<required>

subroutine that returns the array for required set_dates or set_params (none)

=cut

sub required ($self, %args) {
	if ($args{field_name} eq 'set_dates') {
		return { '_ALL_' => [ 'open', 'closed' ]};
	} else {
		return {};
	}
}

1;
