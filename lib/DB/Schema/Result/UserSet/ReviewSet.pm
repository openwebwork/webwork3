package DB::Schema::Result::UserSet::ReviewSet;
use base qw/DB::Schema::Result::UserSet/;
use strict;
use warnings;

use feature 'signatures';
no warnings qw(experimental::signatures);

use DB::Schema::Result::ProblemSet::ReviewSet;

sub valid_dates ($=) {
	return DB::Schema::Result::ProblemSet::ReviewSet::valid_dates();
}

sub required_dates ($=) {
	return DB::Schema::Result::ProblemSet::ReviewSet::required_dates();
}

sub valid_params ($=) {
	return DB::Schema::Result::ProblemSet::ReviewSet::valid_params();
}

sub required_params ($=) {
	return DB::Schema::Result::ProblemSet::ReviewSet::required_params();
}

1;
