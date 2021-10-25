package DB::Schema::Result::UserSet::HWSet;
use DB::WithParams;
use DB::WithDates;

use strict;
use warnings;
use base qw(DB::Schema::Result::UserSet DB::WithParams DB::WithDates);

use DB::Schema::Result::ProblemSet::HWSet;

our @VALID_DATES    = @DB::Schema::Result::ProblemSet::HWSet::VALID_DATES;
our @REQUIRED_DATES = @DB::Schema::Result::ProblemSet::HWSet::REQUIRED_DATES;

our $VALID_PARAMS    = $DB::Schema::Result::ProblemSet::HWSet::VALID_PARAMS;
our $REQUIRED_PARAMS = $DB::Schema::Result::ProblemSet::HWSet::REQUIRED_PARAMS;

1;
