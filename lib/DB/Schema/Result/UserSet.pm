package DB::Schema::Result::UserSet;
use base qw/DBIx::Class::Core/;
use strict;
use warnings; 

use JSON; 


__PACKAGE__->table('user_set');

__PACKAGE__->add_columns(
								user_set_id =>
									{ 
										data_type => 'integer',
										size      => 16,
										is_nullable => 0,
										is_auto_increment => 1,
									},
								set_id =>
									{ 
										data_type => 'integer',
										size      => 16,
										is_nullable => 0,
									},
								user_id  =>
									{ 
										data_type => 'integer',
                    size => 16,   
										is_nullable => 0,
									},
								dates => # store dates as a JSON object
									{
										data_type => 'text',
										size => 256,
										is_nullable => 0,
										default_value => '{}'
									},
								params => # store params as a JSON object
									{
										data_type => 'text',
										size => 256,
										is_nullable => 0,
										default_value => '{}'
									}
								);

__PACKAGE__->set_primary_key('user_set_id');
__PACKAGE__->belongs_to(course_users => 'DB::Schema::Result::CourseUser','user_id');
__PACKAGE__->belongs_to(problem_sets => 'DB::Schema::Result::ProblemSet','set_id');


### Handle the params column using JSON. 

__PACKAGE__->inflate_column('params', {
	inflate => sub {
		decode_json shift;
	},
	deflate => sub {
		encode_json shift; 
	}
});
1;