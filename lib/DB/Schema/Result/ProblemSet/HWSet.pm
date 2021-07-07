package DB::Schema::Result::ProblemSet::HWSet;

use strict;
use warnings;
use base qw(DB::Schema::Result::ProblemSet DB::WithParams DB::WithDates);

our @VALID_DATES = qw/open reduced_scoring due answer/;
our @REQUIRED_DATES = qw/open due answer/;
our $VALID_PARAMS = {
	enable_reduced_scoring => q{[01]},
	visible => q{[01]},
	hide_hint => q{[01]},
	hardcopy_header => q{.*},
	set_header => q{.*},
	description => q{.*}
};

our $REQUIRED_PARAMS = {};

1;