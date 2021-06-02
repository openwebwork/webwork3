package DB::Schema::Result::ProblemSet::ReviewSet;
use base qw/DB::Schema::Result::ProblemSet/;
use strict;
use warnings; 

our @valid_dates = qw/open due answer/;
our @valid_params = qw//;

sub getValidDates {
	return join($self::SUPER->valid_dates, @valid_dates);
}

sub getValidParams {
	return join($self::SUPER->valid_params, @valid_params);
}



1;