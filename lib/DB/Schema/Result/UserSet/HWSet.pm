package DB::Schema::Result::UserSet::HWSet;
use base qw/DB::Schema::Result::UserSet/;
use strict;
use warnings;

use feature 'signatures';
no warnings qw(experimental::signatures);

use DB::Schema::Result::ProblemSet::HWSet;

sub validation ($self, %args) {
	return DB::Schema::Result::ProblemSet::HWSet::validation($self, %args);
}

sub required ($self, %args) {
	return {};
}
use Data::Dumper;
sub additional_validation ($self, %args) {
	return 1 if ($args{field_name} ne 'set_dates');

	my $user_set_dates = $self->get_inflated_column('set_dates');
	# merge with the related problem set
	my $dates = $args{problem_set_dates};
	for (keys %$user_set_dates) { $dates->{$_} = $user_set_dates->{$_}; }

	return DB::Schema::Result::ProblemSet::HWSet::additional_validation($self, field_name => $args{field_name}, merged_dates => $dates);
}

1;
