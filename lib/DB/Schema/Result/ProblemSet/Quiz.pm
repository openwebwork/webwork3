package DB::Schema::Result::ProblemSet::Quiz;
use base qw/DB::Schema::Result::ProblemSet/;
use strict;
use warnings; 

our @valid_dates = 
our @valid_params = qw/timed time_length/;

our @VALID_DATES = qw/open due answer/;
our @REQUIRED_DATES = qw/open due answer/; 
our %VALID_PARAMS = (
	timed => '^[01]$',
	time_length => '\d+',
	);
our @REQUIRED_PARAMS = qw//;

sub getValidDates {
	return join($self::SUPER->valid_dates, @valid_dates);
}

sub getValidParams {
	return join($self::SUPER->valid_params, @valid_params);
}



1;