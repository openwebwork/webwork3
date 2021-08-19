package DB::Schema::Result::ProblemSet::ReviewSet;
use base qw/DB::Schema::Result::ProblemSet/;
use strict;
use warnings;

use Carp;

sub valid_dates {
	return ['open' ,'close'];
}

sub required_dates {
	return ['open' ,'close'];
}

sub valid_params {
	return {};
}

sub required_params {
	return {};
}

1;
