package DB::Schema::Result::ProblemSet::Quiz;
use base qw/DB::Schema::Result::ProblemSet/;
use strict;
use warnings; 

our @VALID_DATES = qw/open due answer/;
our @REQUIRED_DATES = qw/open due answer/; 
our %VALID_PARAMS = (
	timed => '^[01]$',
	time_length => '\d+',
	);
our @REQUIRED_PARAMS = qw//;

sub setParamsAndDates {
	my $self = shift; 
	$self->setParamInfo(\%VALID_PARAMS,\@REQUIRED_PARAMS);
	$self->setDateInfo(\@VALID_DATES,\@REQUIRED_DATES);
}

1;