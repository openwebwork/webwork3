package DB::Schema::Result::UserSet::Quiz;
use base qw/DB::Schema::Result::UserSet/;
use strict;
use warnings;

use feature 'signatures';
no warnings qw(experimental::signatures);

use DB::Schema::Result::ProblemSet::Quiz;

sub valid_dates ($=) {
	return DB::Schema::Result::ProblemSet::Quiz::valid_dates();
}

sub required_dates ($=) {
	return DB::Schema::Result::ProblemSet::Quiz::required_dates();
}

sub valid_params ($=) {
	return DB::Schema::Result::ProblemSet::Quiz::valid_params();
}

sub required_params ($=) {
	return DB::Schema::Result::ProblemSet::Quiz::required_params();
}

1;
