package DB::Schema::Result::UserParam;
use base qw/DBIx::Class::Core/;
use strict;
use warnings; 


__PACKAGE__->table('user_param');

__PACKAGE__->add_columns(
								user_param_id =>
									{ 
										data_type => 'integer',
										size      => 16,
										is_nullable => 0,
										is_auto_increment => 1,
									},
								user_id =>
									{ 
										data_type => 'integer',
										size      => 16,
										is_nullable => 0,
										is_foreign_key => 1
									},
								course_id =>
									{ 
										data_type => 'integer',
										size      => 16,
										is_nullable => 0,
										is_foreign_key => 1
									},
								section => 
									{
										data_type => 'text',
										size => 256,
										is_nullable => 1
									},
								recitation => 
									{
										data_type => 'text',
										size => 256,
										is_nullable => 1
									},
								comment => 
									{
										data_type => 'text',
										size => 256,
										is_nullable => 1
									},
								roles => 
									{
										data_type => 'text',
										size => 256,
										is_nullable => 1
									}
								);

__PACKAGE__->set_primary_key('user_param_id');

__PACKAGE__->add_unique_constraint([qw/user_id course_id/]);
__PACKAGE__->belongs_to(users => 'DB::Schema::Result::User','user_id');

1;