package DB::Schema::Result::ProblemSet::HWSet;
use base qw/DB::Schema::Result::ProblemSet/;
use strict;
use warnings; 

use Carp;
use Data::Dump qw/dd/;

our @VALID_DATES = qw/open reduced_scoring due answer/;
our @REQUIRED_DATES = qw/open due answer/; 
our %VALID_PARAMS = (
	has_reduced_scoring => '[01]',
	visible => '[01]',
	hide_hints => '[01]'
	);
our @REQUIRED_PARAMS = qw//;


sub isValid {
	my $self = shift; 
	$self->validParamFields();
	$self->validateParams();
	$self->validDateFields();
	$self->hasRequiredDateFields();
	$self->validDateValues();
	croak "The dates are invalid. " unless $self->checkDates();
	return 1;
}

sub validDateFields {
	my $self = shift;
	return $self->SUPER::validDateFields(\@VALID_DATES);
}

sub hasRequiredDateFields {
	my $self = shift;
	return $self->SUPER::hasRequiredDateFields(\@REQUIRED_DATES);
}

sub validDateValues {
	my $self = shift; 
	return $self->SUPER::validDateValues(\@VALID_DATES);
}

sub checkDates { 
	my $self = shift; 
	return (defined($self->dates->{reduced_scoring}) &&
			$self->dates->{open} <= $self->dates->{reduced_scoring} &&
			$self->dates->{reduced_scoring} <= $self->dates->{due} &&
			$self->dates->{due} <= $self->dates->{answer}) 
		|| ($self->dates->{open} <= $self->dates->{due} &&
				$self->dates->{due} <= $self->dates->{answer}); 
}

sub validParamFields {
	my $self = shift; 
	return $self->SUPER::validParamFields(\%VALID_PARAMS);
}

sub validateParams {
	my $self = shift; 
	return $self->SUPER::validateParams(\%VALID_PARAMS);
}

1;