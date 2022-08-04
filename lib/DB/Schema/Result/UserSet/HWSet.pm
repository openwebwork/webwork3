package DB::Schema::Result::UserSet::HWSet;

use strict;
use warnings;
use feature 'signatures';
no warnings qw/experimental::signatures/;

use base qw/DB::Schema::Result::UserSet/;
use DB::Schema::Result::ProblemSet::HWSet;

sub valid_fields ($self, %args) {
	return DB::Schema::Result::ProblemSet::HWSet::valid_fields($self, %args);
}

sub required ($self, %args) {
	return {};
}

sub additional_validation ($self, %args) {
	return DB::Schema::Result::ProblemSet::HWSet::additional_validation($self, %args);
}

1;
