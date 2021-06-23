package DB::Schema::Result::ProblemSet::HWSet;
@ISA = qw(DB::Schema::Result::ProblemSet DB::WithParams DB::WithDates);
use strict;
use warnings; 

our @VALID_DATES = qw/open reduced_scoring due answer/;
our @REQUIRED_DATES = qw/open due answer/; 
our $VALID_PARAMS = {
	enable_reduced_scoring => '[01]',
	visible => '[01]',
	hide_hint => '[01]',
	hardcopy_header => '.*',
	set_header => '.*',
	description => '.*'
};

our $REQUIRED_PARAMS = {};

1;