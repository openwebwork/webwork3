package DB::Schema::Result::UserProblem;
use base qw/DBIx::Class::Core/;
use strict;
use warnings;

use JSON; 

### this is the table that stores problems for a given Problem Set

__PACKAGE__->table('user_problem');

__PACKAGE__->add_columns(
	user_problem_id => {
		data_type         => 'integer',
		size              => 16,
		is_nullable       => 0,
		is_auto_increment => 1,
	},
	problem_id => {
		data_type   => 'integer',
		size        => 16,
		is_nullable => 0,
	},
	user_id => {
		data_type   => 'integer',
		size        => 16,
		is_nullable => 0,
	},
	seed => {
		data_type   => 'integer',
		size        => 16,
		is_nullable => 0,
	},
	status => {
		data_type   => 'integer',
		size        => 16,
		is_nullable => 0,
	},
	problem_version => {
		data_type   => 'integer',
		size        => 16,
		is_nullable => 0,
		default_value => 1,
	},
	params => {
		data_type => 'text',
		size      => 256,
		is_nullable => 0,
		default_value => '{}'
	}
);

__PACKAGE__->set_primary_key('user_problem_id');

__PACKAGE__->belongs_to( problems => 'DB::Schema::Result::Problem', 'problem_id' );
__PACKAGE__->belongs_to( course_users => 'DB::Schema::Result::CourseUser', 'user_id' );

__PACKAGE__->inflate_column(
	'params',
	{
		inflate => sub {
			decode_json shift;
		},
		deflate => sub {
			encode_json shift;
		}
	}
);


1;
