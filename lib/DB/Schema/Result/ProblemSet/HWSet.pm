package DB::Schema::Result::ProblemSet::HWSet;
@ISA = qw(DB::Schema::Result::ProblemSet DB::WithParams DB::WithDates);
use strict;
use warnings; 

use Carp;
use Data::Dump qw/dd/;

our @VALID_DATES = qw/open reduced_scoring due answer/;
our @REQUIRED_DATES = qw/open due answer/; 
our %VALID_PARAMS = (
	has_reduced_scoring => '[01]',
	visible => '[01]',
	hide_hints => '[01]'
	);
our @REQUIRED_PARAMS = qw//;

# sub setParamsAndDates {
# 	my $self = shift; 
# 	$self->setParamInfo(\%VALID_PARAMS,\@REQUIRED_PARAMS);
# 	$self->setDateInfo(\@VALID_DATES,\@REQUIRED_DATES);
# }

1;