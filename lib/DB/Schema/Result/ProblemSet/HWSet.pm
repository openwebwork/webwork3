package DB::Schema::Result::ProblemSet::HWSet;

use strict;
use warnings;
use base qw(DB::Schema::Result::ProblemSet DB::WithParams DB::WithDates);

sub valid_dates {
	return ['open', 'reduced_scoring', 'due' ,'answer'];
}

sub required_dates {
	return ['open', 'due' ,'answer'];
}

sub valid_params {
	return {
		enable_reduced_scoring => q{[01]},
		hide_hint => q{[01]},
		hardcopy_header => q{.*},
		set_header => q{.*},
		description => q{.*}
	};
}

sub required_params {
	return {};
}

1;