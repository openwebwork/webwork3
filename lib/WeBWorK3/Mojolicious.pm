package WeBWorK3::Mojolicious;
use warnings;
use strict;

use Try::Tiny;

our $VERSION = '2.99';

use Data::Dump qw/dd/;

our $exception_handler = sub {
	my ($next, $c) = @_;
	## only test requests that start with "/api"
	if ($c->req->url->to_string =~ /\/api/x) {
		try {
			$next->();
		} catch {
			my $output = {exception => ref($_)};
			$output->{message} = $_->message if ($_ && ref($_) eq 'Mojo::Exception' or ref($_) =~ /^DB::Exception/x);
			$output->{message} = $_ if ($_ && ref($_) eq 'DBIx::Class::Exception');
			$c->render(json => $output, status => 250);
		};
	} else {
		$next->();
	}
};

my $ignore_permissions = 1;

sub has_permission {
	my ($user,$perm) = @_;
	if ($perm->{allowed_users}) {
		return "" unless $user->{role};
		return grep {$_ eq $user->{role} } @{$perm->{allowed_users}};
	}
	return 1 unless ($perm->{check_permission} || $perm->{admin_required});
	return ($user && $user->{is_admin}) if $perm->{admin_required};

	return 1;
}

## check permission for /api routes

our $check_permission = sub {
	my ($next, $c, $action) = @_;
	return $next->() if ($c->ignore_permissions || $c->req->url->to_string =~ /\/api\/login/x);
	my $controller_name = $c->{stash}->{controller};
	my $action_name = $c->{stash}->{action};
	if ($c->req->url->to_string =~ /\/api/x) {
		if (has_permission($c->current_user,$c->perm_table->{$controller_name}->{$action_name})) {
			return $next->();
		} else {
			$c->render( json => { has_permission => 0, msg => "permission error"});
		}
	} else {
		$next->();
	}
};

1;
