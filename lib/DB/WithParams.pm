package DB::WithParams;

use Carp; 
use Array::Utils qw/array_minus intersect/;

my $valid_params;
my $required_params; 

sub setParamInfo {
	my ($self,$params,$req) = @_;
	$valid_params = $params; 
	$required_params = $req; 
}


sub validParams {
	my $self = shift; 
	$self->validParamFields();
	$self->validateParams();
	return 1;
}

# check if the param fields are valid (depending on the type of ProblemSet)

sub validParamFields {
	my ($self,$valid_param_fields) = @_; 
	return 1 unless defined($self->params);
	my @valid_fields = keys %$valid_param_fields;
	my @fields = keys %{$self->params};
	my @inter = intersect(@fields,@valid_fields);
	if (scalar(@inter) != scalar(@fields)) {
		my @bad_fields = array_minus(@fields, @valid_fields); 
		croak "The field(s):  " . join(", ",@bad_fields) . " are not valid";
	}
	return 1;
}

sub validateParams {
	my ($self,$valid_params) = @_;
	return 1 unless defined $self->params; 
	for my $key (keys %{$self->params}){
		my $re = $valid_params->{$key};
		croak "The field $key of params is not valid" unless $self->params->{$key} =~ qr/^$re$/; 
	} 
	return 1; 
}

1;