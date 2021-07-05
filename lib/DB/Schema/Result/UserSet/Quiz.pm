package DB::Schema::Result::UserSet::Quiz;
use base qw/DB::Schema::Result::UserSet/;
use strict;
use warnings;

use DB::Schema::Result::ProblemSet::Quiz;

our @VALID_DATES = @DB::Schema::Result::ProblemSet::Quiz::VALID_DATES;
our @REQUIRED_DATES = @DB::Schema::Result::ProblemSet::Quiz::REQUIRED_DATES;

our $VALID_PARAMS = $DB::Schema::Result::ProblemSet::Quiz::VALID_PARAMS;
our $REQUIRED_PARAMS = $DB::Schema::Result::ProblemSet::Quiz::REQUIRED_PARAMS;

1;