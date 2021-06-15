package DB::Schema::Result::UserSet::Quiz;
use base qw/DB::Schema::Result::UserSet/;
use strict;
use warnings; 

our @VALID_DATES = qw/open due answer/;
our @REQUIRED_DATES = qw/open due answer/; 
our $VALID_PARAMS = {
	timed => '^[01]$',
	time_length => '\d+',
};
our $REQUIRED_PARAMS = {};

1;