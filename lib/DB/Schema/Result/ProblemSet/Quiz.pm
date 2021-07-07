package DB::Schema::Result::ProblemSet::Quiz;

use strict;
use warnings;
use base qw/DB::Schema::Result::ProblemSet/;

our @VALID_DATES = qw/open due answer/;
our @REQUIRED_DATES = qw/open due answer/;
our $VALID_PARAMS = {
	timed => q{^[01]$},
	time_length => q{\d+},
};
our $REQUIRED_PARAMS = {};

1;