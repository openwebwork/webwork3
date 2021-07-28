use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WeBWorK3',
    license             => 'perl',
    dist_abstract       => 'An open-source online homework system',
    dist_author         => 'openwebwork <https://openwebwork.org>',
    build_requires => {
        'Test::More' => '0.10',
    },
    test_files => 't/**/*.t'
);

$builder->create_build_script();