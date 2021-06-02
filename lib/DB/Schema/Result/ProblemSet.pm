package DB::Schema::Result::ProblemSet;
use base qw/DBIx::Class::Core/;

use strict;
use warnings; 
use Data::Dump qw/dd/;
use Array::Utils qw/array_minus intersect/;
use JSON; 
use Carp; 

__PACKAGE__->load_components(qw/DynamicSubclass Core/);

__PACKAGE__->table('problem_set');

__PACKAGE__->add_columns(
								set_id =>
									{ 
										data_type => 'integer',
										size      => 16,
										is_nullable => 0,
										is_auto_increment => 1,
									},
								name =>
									{ 
										data_type => 'text',
										size      => 256,
										is_nullable => 0,
									},
								course_id  =>
									{ 
										data_type => 'integer',
										size => 16,   
										is_nullable => 1,
									},
								dates => # store dates as a JSON object
									{
										data_type => 'text',
										size => 256,
										is_nullable => 1
									},
								type => 
									{
										data_type => "int",
										default_value => 1,
										size => 16
									},
								params => # store params as a JSON object
									{
										data_type => 'text',
										size => 256,
										is_nullable => 1
									}
								);

#
# This defines the non-abstract classes of ProblemSets.  
# 

__PACKAGE__->typecast_map(type => {
    1 => 'DB::Schema::Result::ProblemSet::HWSet',
    2 => 'DB::Schema::Result::ProblemSet::Quiz',
    3 => 'DB::Schema::Result::ProblemSet::JITAR',
		4 => 'DB::Schema::Result::ProblemSet::ReviewSet',
});

__PACKAGE__->set_primary_key('set_id');
__PACKAGE__->belongs_to(courses => 'DB::Schema::Result::Course','course_id');
__PACKAGE__->has_many(problems => 'DB::Schema::Result::Problem','set_id');
__PACKAGE__->has_many(user_sets => 'DB::Schema::Result::UserSet','set_id');

### Handle the params column using JSON. 

__PACKAGE__->inflate_column('params', {
	inflate => sub {
		decode_json shift;
	},
	deflate => sub {
		encode_json shift; 
	}
});

__PACKAGE__->inflate_column('dates', {
	inflate => sub {
		decode_json shift;
	},
	deflate => sub {
		encode_json shift; 
	}
});

sub validDateFields {
	my ($self,$valid_date_fields) = @_;
	my @fields = keys %{$self->dates}; 
	my @bad_fields = array_minus(@fields, @$valid_date_fields);  # if this is not empty, there are illegal fields
	if (scalar(@bad_fields) != 0) {
		croak "The field(s):  " . join(", ",@bad_fields) . " are not valid";
	}
	return 1;
}

# check that the value of each date field is valid.

sub validDateValues {
	my ($self,$valid_date_fields) = @_;
	for my $key (@$valid_date_fields) {
		next unless defined($self->dates->{$key});
		die "The date $key is not in the proper form." unless $self->dates->{$key} =~ /^\d+$/; 
	}
	return 1; 
}

sub hasRequiredDateFields {
	my ($self,$req_date_fields) = @_;
	my @fields = keys %{$self->dates}; 
	my @bad_fields = array_minus(@$req_date_fields,@fields);  
	if (scalar(@bad_fields) != 0) {
		croak "The field(s): " . join(", ",@bad_fields) . " are required for this.";
	}
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