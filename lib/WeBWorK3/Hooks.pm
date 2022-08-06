package WeBWorK3::Hooks;

use warnings;
use strict;
use feature 'signatures';
no warnings qw(experimental::signatures);

use Try::Tiny;

our $VERSION = '2.99';

our $exception_handler = sub ($next, $c) {
	# Only test requests that start with '/api'.
	if ($c->req->url->to_string =~ /\/api/x) {
		try {
			$next->();
		} catch {
			my $output = { exception => ref($_) };
			$output->{message} = $_->message
				if (ref($_) && (ref($_) eq 'Mojo::Exception' || ref($_) =~ /^DB::Exception/x));
			$output->{message} = $_ if ($_ && ref($_) eq 'DBIx::Class::Exception');
			$c->log->error($output->{message});
			$c->render(json => $output, status => 500);
		};
	} else {
		$next->();
	}
};

our $notify_expiry = sub ($c) {
	$c->res->headers->header('x-expiry' => time + $c->app->sessions->default_expiration)
		if ($c->signature_exists());
};

1;
