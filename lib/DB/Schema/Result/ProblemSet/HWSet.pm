package DB::Schema::Result::ProblemSet::HWSet;

use strict;
use warnings;
use feature 'signatures';
no warnings qw/experimental::signatures/;

use base qw/DB::Schema::Result::ProblemSet DB::Validation/;

=head1 DESCRIPTION

This is the database schema for a HWSet, a subclass of a C<DB::Schema::Result::ProblemSet>

In particular, this contains the methods C<valid_fields>, C<required>,
and C<additional_validation>.  See C<DB::Validation>
for details on these.

=cut

=head2 C<valid_fields>

subroutine that returns a hash of the validation for both set_dates and set_params.

=cut

sub valid_fields ($self, $field_name) {
	if ($field_name eq 'set_dates') {
		return {
			open                   => q{\d+},
			reduced_scoring        => q{\d+},
			due                    => q{\d+},
			answer                 => q{\d+},
			enable_reduced_scoring => 'bool'
		};
	} elsif ($field_name eq 'set_params') {
		return {
			hide_hint       => 'bool',
			hardcopy_header => q{.*},
			set_header      => q{.*},
			description     => q{.*}
		};
	} else {
		return {};
	}
}

=head2 C<additional_validation>

subroutine that checks any additional validation

=cut

sub additional_validation ($self, $field_name) {
	return 1 if ($field_name ne 'set_dates');

	my $dates = $self->get_inflated_column('set_dates');

	if ($dates->{enable_reduced_scoring}) {
		DB::Exception::ImproperDateOrder->throw(message => 'The dates are not in order')
			unless $dates->{open} <= $dates->{reduced_scoring}
			&& $dates->{reduced_scoring} <= $dates->{due}
			&& $dates->{due} <= $dates->{answer};
	} else {
		DB::Exception::ImproperDateOrder->throw(message => 'The dates are not in order')
			unless $dates->{open} <= $dates->{due}
			&& $dates->{due} <= $dates->{answer};
	}
	return 1;
}

=head2 C<required>

subroutine that returns the array for required set_dates or set_params (none)

=cut

sub required ($self, $field_name) {
	if ($field_name eq 'set_dates') {
		return { '_ALL_' => [ 'open', 'due', 'answer' ] };
	} else {
		return {};
	}
}

1;
