package DB::Schema::Result::ProblemSet::Quiz;

use strict;
use warnings;
use base qw(DB::Schema::Result::ProblemSet DB::WithParams DB::WithDates);

sub valid_dates {
	return ['open', 'due' ,'answer'];
}

sub required_dates {
	return ['open', 'due' ,'answer'];
}

sub valid_params {
	return {
		timed => q{^[01]$},
		quiz_length => q{\d+},
	};
}

sub required_params {
	return {};
}

1;
