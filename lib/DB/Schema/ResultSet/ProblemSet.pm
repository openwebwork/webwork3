package DB::Schema::ResultSet::ProblemSet;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

use Carp;
use Data::Dump qw/dd/;


=pod
 
=head1 DESCRIPTION
 
This is the functionality of a ProblemSet in WeBWorK.  This package is based on 
<code>DBIx::Class::ResultSet</code>.  The basics are a CRUD for ProblemSets;  
 
=cut

=pod
=head2 getProblemSets

This gets a list of all ProblemSet (and set-like objects) stored in the database in the <code>courses</codes> table. 

=head3 input 

none

=head3 output 

An array of courses as a <code>DBIx::Class::ResultSet::ProblemSet</code> object.  

=cut

sub getProblemSets {
	my $self = shift;
	my @all_sets = $self->search(undef,
		{
			join => 'courses'
		}); 
	return map { {$_->get_inflated_columns,$_->courses->get_columns};} @all_sets;
} 

1;