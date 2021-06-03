package DB::Schema::Result::ProblemSet::ReviewSet;
use base qw/DB::Schema::Result::ProblemSet/;
use strict;
use warnings; 

use Carp;

our @VALID_DATES = qw/open closed/;
our @REQUIRED_DATES = qw/open closed/; 
our %VALID_PARAMS = ();
our @REQUIRED_PARAMS = qw//;

sub setParamsAndDates {
	my $self = shift; 
	$self->setParamInfo(\%VALID_PARAMS,\@REQUIRED_PARAMS);
	$self->setDateInfo(\@VALID_DATES,\@REQUIRED_DATES);
}

1;