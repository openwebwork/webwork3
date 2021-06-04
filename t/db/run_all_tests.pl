# run all tests in this directory

use TAP::Harness;
use Data::Dump qw/dd/;

`perl build_db.pl` unless -e 'sample_db.sqlite';


my @test_files = glob("*.t");


my %args = ( verbosity => 0, lib => [ '.',]);
my $harness = TAP::Harness->new( \%args );

$harness->runtests(@test_files);


1;