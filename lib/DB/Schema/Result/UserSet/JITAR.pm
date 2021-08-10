package DB::Schema::Result::UserSet::JITAR;
use DB::WithParams;
use DB::WithDates;

use strict;
use warnings;
use base qw(DB::Schema::Result::UserSet DB::WithParams DB::WithDates);

use DB::Schema::Result::ProblemSet::JITAR;

our @VALID_DATES = @DB::Schema::Result::ProblemSet::JITAR::VALID_DATES;
our @REQUIRED_DATES = @DB::Schema::Result::ProblemSet::JITAR::REQUIRED_DATES;

our $VALID_PARAMS = $DB::Schema::Result::ProblemSet::JITAR::VALID_PARAMS;
our $REQUIRED_PARAMS = $DB::Schema::Result::ProblemSet::JITAR::REQUIRED_PARAMS;


1;
