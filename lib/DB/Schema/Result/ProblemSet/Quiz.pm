package DB::Schema::Result::ProblemSet::Quiz;

use strict;
use warnings;
use base qw/DB::Schema::Result::ProblemSet/;

sub valid_dates {
	return ['open', 'due' ,'answer'];
}

sub required_dates {
	return ['open', 'due' ,'answer'];
}

sub valid_params {
	return {
		timed => q{^[01]$},
		time_length => q{\d+},
	};
}

sub required_params {
	return {};
}

1;