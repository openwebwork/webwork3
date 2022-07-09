package DB::Schema::Result::UserSet::HWSet;
use base qw/DB::Schema::Result::UserSet/;
use strict;
use warnings;

use feature 'signatures';
no warnings qw(experimental::signatures);

use DB::Schema::Result::ProblemSet::HWSet;

sub valid_dates ($=) {
	return DB::Schema::Result::ProblemSet::HWSet::valid_dates();
}

sub required_dates ($=) {
	return DB::Schema::Result::ProblemSet::HWSet::required_dates();
}

sub optional_fields_in_dates ($=) {
	return DB::Schema::Result::ProblemSet::HWSet::optional_fields_in_dates();
}

sub valid_params ($=) {
	return DB::Schema::Result::ProblemSet::HWSet::valid_params();
}

sub required_params ($=) {
	return DB::Schema::Result::ProblemSet::HWSet::required_params();
}

1;
