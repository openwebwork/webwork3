package DB::Schema;

## This is the base package for the Schema for the WeBWorK.

use warnings;
use strict;

use base qw/DBIx::Class::Schema/;
__PACKAGE__->load_namespaces;

1;
