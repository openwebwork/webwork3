#!/usr/bin/env perl

use warnings;
use strict;

# Run all tests in this directory.

use TAP::Harness;
use File::Basename qw/dirname/;

my $test_dir = dirname(__FILE__);

`perl $test_dir/build_db.pl` unless -e 'sample_db.sqlite';

my @test_files = glob("$test_dir/*.t");

my %args    = (verbosity => 0, lib => [ '.', ]);
my $harness = TAP::Harness->new(\%args);

$harness->runtests(@test_files);

1;
