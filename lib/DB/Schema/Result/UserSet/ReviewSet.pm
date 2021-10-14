package DB::Schema::Result::UserSet::ReviewSet;
use base qw/DB::Schema::Result::UserSet/;
use strict;
use warnings;

use DB::Schema::Result::ProblemSet::ReviewSet;

our @VALID_DATES    = @DB::Schema::Result::ProblemSet::ReviewSet::VALID_DATES;
our @REQUIRED_DATES = @DB::Schema::Result::ProblemSet::ReviewSet::REQUIRED_DATES;

our $VALID_PARAMS    = $DB::Schema::Result::ProblemSet::ReviewSet::VALID_PARAMS;
our $REQUIRED_PARAMS = $DB::Schema::Result::ProblemSet::ReviewSet::REQUIRED_PARAMS;

1;
