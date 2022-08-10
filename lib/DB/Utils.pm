package DB::Utils;

use warnings;
use strict;
use feature 'signatures';
no warnings qw/experimental::signatures/;

require Exporter;
use base qw/Exporter/;
our @EXPORT_OK = qw/getCourseInfo getUserInfo getSetInfo updateAllFields
	getPoolInfo getProblemInfo getPoolProblemInfo removeLoginParams updatePermissions/;

use Clone qw/clone/;
use List::Util qw/first/;
use Scalar::Util qw/reftype/;
use YAML::XS qw/LoadFile/;

use Exception::Class ('DB::Exception::ParametersNeeded');

sub getCourseInfo ($in) {
	return _get_info($in, qw/course_id course_name/);
}

sub getUserInfo ($in) {
	return _get_info($in, qw/user_id username email/);
}

sub getSetInfo ($in) {
	return _get_info($in, qw/set_id set_name/);
}

sub getPoolInfo ($in) {
	return _get_info($in, qw/problem_pool_id pool_name/);
}

sub getProblemInfo ($in) {
	return _get_info($in, qw/problem_number set_problem_id/);
}

sub getPoolProblemInfo ($in) {
	return _get_info($in, qw/library_id pool_problem_id/);
}

# This is a generic internal subroutine to check that the info passed in contains certain fields.

# $input_info is a hashref containing various search information.
# @fields is an array of the valid fields to be parsed.

sub _get_info ($input_info, @fields) {
	my $output_info = {};
	for my $key (@fields) {
		$output_info->{$key} = $input_info->{$key} if defined($input_info->{$key});
	}

	DB::Exception::ParametersNeeded->throw(message => 'You must pass in only one of ' . join(', ', @fields) . '.')
		if scalar(keys %$output_info) > 1;
	DB::Exception::ParametersNeeded->throw(message => 'You must pass exactly one of ' . join(', ', @fields) . '.')
		if scalar(keys %$output_info) < 1;

	return $output_info;
}

=head1 updateAllFields

This method updates the fields of the first argument with any from the second argument.
This returns the hashref with both the original and any replacements.

=cut

sub updateAllFields ($current_fields, $updated_fields) {
	my $fields_to_return = clone($current_fields);
	for my $key (keys %$updated_fields) {
		if (defined(reftype($updated_fields->{$key})) && reftype($updated_fields->{$key}) eq 'HASH') {
			$fields_to_return->{$key} = updateAllFields($current_fields->{$key} || {}, $updated_fields->{$key});
		} else {
			$fields_to_return->{$key} =
				defined($updated_fields->{$key}) ? $updated_fields->{$key} : $current_fields->{$key};
		}
	}
	return $fields_to_return;
}

=head2 removeLoginParams

This removes the login_params field from a user.  There is no reason the login_params are needed
off the server.

=cut

sub removeLoginParams ($params) {
	delete $params->{login_params};
	return $params;
}

=head2 updatePermissions

The updatePermissions subroutine loads the roles and permissions from a YAML file into the database.

=cut

sub updatePermissions ($ww3_conf, $role_perm_file) {

	my $config = LoadFile($ww3_conf);

	# Connect to the database.
	my $schema = DB::Schema->connect(
		$config->{database_dsn},
		$config->{database_user},
		$config->{database_password},
		{ quote_names => 1 }
	);

	# load any YAML true/false as booleans, not string true/false.
	local $YAML::XS::Boolean = "JSON::PP";
	my $role_perm = LoadFile($role_perm_file);

	print "Rebuilding all roles and permissions in database\n";

	# clear out the tables role, db_perm, ui_perm
	$schema->resultset('Role')->delete_all;
	$schema->resultset('DBPermission')->delete_all;
	$schema->resultset('UIPermission')->delete_all;

	# Add the roles to the database.

	my @roles = map { { role_name => $_ }; } @{ $role_perm->{roles} };
	$schema->resultset('Role')->populate(\@roles);

	# fill the database permissions table
	for my $category (keys %{ $role_perm->{db_permissions} }) {
		for my $action (keys %{ $role_perm->{db_permissions}->{$category} }) {
			$schema->resultset('DBPermission')->create({
				category          => $category,
				action            => $action,
				admin_required    => $role_perm->{db_permissions}->{$category}->{$action}->{admin_required},
				authenticated     => $role_perm->{db_permissions}->{$category}->{$action}->{authenticated},
				allow_self_access => $role_perm->{db_permissions}->{$category}->{$action}->{allow_self_access}
			});
		}
	}

	# map roles to database permissions
	for my $category (keys %{ $role_perm->{db_permissions} }) {
		for my $action (keys %{ $role_perm->{db_permissions}->{$category} }) {
			my $db_perm = $schema->resultset('DBPermission')->find({
				category => $category,
				action   => $action
			});
			my $allowed_roles = $role_perm->{db_permissions}->{$category}->{$action}->{allowed_roles} // [];

			next unless $allowed_roles;

			# check that the allowed roles is '*' (any role) or that the given role exists.
			if (scalar(@$allowed_roles) == 1 && $allowed_roles->[0] eq '*') {
				my @all_roles = $schema->resultset('Role')->search({});
				for my $role (@all_roles) {
					$db_perm->add_to_roles({ $role->get_columns });
				}
			} else {
				for my $role_name (@$allowed_roles) {
					my $role = $schema->resultset('Role')->find({ role_name => $role_name });
					die "The role '$role_name' does not exist." unless defined $role;

					$db_perm->add_to_roles({ $role->get_columns });
				}
			}
		}
	}

	# add the UI permissions

	for my $route (keys %{ $role_perm->{ui_permissions} }) {
		my $allowed_roles = $role_perm->{ui_permissions}->{$route}->{allowed_roles} // [];

		# check that the allowed roles exist.
		for my $role (@$allowed_roles) {
			next if $role eq '*';
			my $role_in_db = $schema->resultset('Role')->find({ role_name => $role });
			die "The role '$role' does not exist." unless defined $role_in_db;
		}

		$schema->resultset('UIPermission')->create({
			route             => $route,
			allowed_roles     => $allowed_roles,
			admin_required    => $role_perm->{ui_permissions}->{$route}->{admin_required},
			allow_self_access => $role_perm->{ui_permissions}->{$route}->{allow_self_access}
		});
	}
	return;
}

1;
