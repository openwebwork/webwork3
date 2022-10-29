package TestMysqld;

=head1 TestMysqld

This is a slightly simplified version of the Test::mysqld package.  See
L<https://metacpan.org/pod/Test::mysqld> for usage.  However the
C<copy_data_from> option, the C<start_mysqlds> and C<stop_mysqlds> methods, and
all POD have been removed.  In addition the code has been rewritten to not
depend on the Class::Accessor::Lite and File::Copy::Recursive packages.

=cut

use strict;
use warnings;
use feature 'signatures';
no warnings qw/experimental::signatures/;

use Cwd;
use DBI;
use File::Temp qw(tempdir);
use POSIX qw(SIGTERM WNOHANG);
use Time::HiRes qw(sleep);

our $errstr;
our @SEARCH_PATHS = qw(/usr/local/mysql);

sub new ($klass, @options) {
	my $self = bless {
		auto_start            => 2,
		base_dir              => undef,
		my_cnf                => {},
		mysqld                => undef,
		use_mysqld_initialize => undef,
		mysql_install_db      => undef,
		pid                   => undef,
		_owner_pid            => undef,
		@options == 1 ? %{ $options[0] } : @options,
		_owner_pid => $$
	}, $klass;

	if (defined $self->{base_dir}) {
		$self->{base_dir} = cwd . '/' . $self->{base_dir} if $self->{base_dir} !~ m|^/|;
	} else {
		$self->{base_dir} = tempdir(CLEANUP => $ENV{TEST_MYSQLD_PRESERVE} ? undef : 1);
	}

	$self->{my_cnf}{socket}   ||= "$self->{base_dir}/tmp/mysql.sock";
	$self->{my_cnf}{datadir}  ||= "$self->{base_dir}/var";
	$self->{my_cnf}{pid_file} ||= "$self->{base_dir}/tmp/mysqld.pid";
	$self->{my_cnf}{tmpdir}   ||= "$self->{base_dir}/tmp";

	if (!defined $self->{mysqld}) {
		my $prog = _find_program('mysqld', qw/bin libexec sbin/) or die 'unable to find mysqld program';
		$self->{mysqld} = $prog;
	}
	if (!defined $self->{use_mysqld_initialize}) {
		$self->{use_mysqld_initialize} = $self->_use_mysqld_initialize;
	}

	if ($self->{auto_start}) {
		die 'mysqld is already running (' . $self->{my_cnf}{pid_file} . ')'
			if -e $self->{my_cnf}{pid_file};

		$self->setup if $self->{auto_start} >= 2;
		$self->start;
	}

	return $self;
}

sub DESTROY ($self) {
	$self->stop if defined $self->{pid} && $$ == $self->{_owner_pid};
	return;
}

sub dsn ($self, %args) {
	$args{port} ||= $self->{my_cnf}{port} if $self->{my_cnf}{port};
	if (defined $args{port}) {
		$args{host} ||= $self->{my_cnf}{host} || '127.0.0.1';
	} else {
		$args{mysql_socket} ||= $self->{my_cnf}{socket};
	}
	$args{user}   = $self->{my_cnf}{user} if $self->{my_cnf}{user};
	$args{dbname} = $self->{my_cnf}{dbname} // 'test';
	return 'DBI:mysql:' . join(';', map {"$_=$args{$_}"} sort keys %args);
}

sub start ($self) {
	return if defined $self->{pid};
	$self->spawn;
	$self->wait_for_setup;
	return;
}

sub spawn ($self) {
	return if defined $self->{pid};

	## no critic (InputOutput::RequireBriefOpen)
	open my $logfh, '>>', "$self->{base_dir}/tmp/mysqld.log"
		or die "failed to create log file: $self->{base_dir}/tmp/mysqld.log:$!";
	my $pid = fork;
	die "fork(2) failed:$!" unless defined $pid;
	if ($pid == 0) {
		open STDOUT, '>&', $logfh or die "dup(2) failed:$!";
		open STDERR, '>&', $logfh or die "dup(2) failed:$!";
		if ($self->{my_cnf}{user} eq 'root') {
			exec($self->{mysqld}, "--defaults-file=$self->{base_dir}/etc/my.cnf", '--user=root');
		} else {
			exec($self->{mysqld}, "--defaults-file=$self->{base_dir}/etc/my.cnf");
		}
		die "failed to launch mysqld:$?";
	}
	close $logfh;
	## use critic (InputOutput::RequireBriefOpen)
	$self->{pid} = $pid;

	return;
}

sub wait_for_setup ($self) {
	return unless defined $self->{pid};
	my $pid = $self->{pid};
	while (!-e $self->{my_cnf}{pid_file}) {
		if (waitpid($pid, WNOHANG) > 0) {
			die "*** failed to launch mysqld ***\n" . $self->read_log;
		}
		sleep 0.1;
	}

	# create 'test' database
	my $dbh = DBI->connect($self->dsn)                                               or die $DBI::errstr;
	$dbh->do('CREATE DATABASE IF NOT EXISTS ' . ($self->{my_cnf}{dbname} // 'test')) or die $dbh->errstr;

	return;
}

sub stop ($self, $sig = SIGTERM) {
	return unless defined $self->{pid};
	$self->send_stop_signal($sig);
	$self->wait_for_stop;
	return;
}

sub send_stop_signal ($self, $sig = SIGTERM) {
	return unless defined $self->{pid};
	kill $sig, $self->{pid};
	return;
}

sub wait_for_stop ($self) {
	local $?;    # waitpid may change this value :/
	while (waitpid($self->{pid}, 0) <= 0) { }
	$self->{pid} = undef;
	# might remain for example when sending SIGKILL
	unlink $self->{my_cnf}{pid_file};
	return;
}

sub setup ($self) {
	# (re)create directory structure
	mkdir $self->{base_dir};
	for my $subdir (qw/etc var tmp/) {
		mkdir "$self->{base_dir}/$subdir";
	}

	# my.cnf
	open my $fh, '>', "$self->{base_dir}/etc/my.cnf"
		or die "failed to create file: $self->{base_dir}/etc/my.cnf:$!";
	print $fh "[mysqld]\n";
	print $fh map { defined $self->{my_cnf}{$_} && length $self->{my_cnf}{$_} ? "$_=$self->{my_cnf}{$_}\n" : "$_\n"; }
		sort keys %{ $self->{my_cnf} };
	close $fh;

	# mysql_install_db
	if (!-d "$self->{base_dir}/var/mysql") {
		my $cmd = $self->{use_mysqld_initialize} ? $self->{mysqld} : do {
			if (!defined $self->{mysql_install_db}) {
				my $prog = _find_program('mysql_install_db', qw/bin scripts/)
					or die 'failed to find mysql_install_db';
				$self->{mysql_install_db} = $prog;
			}
			$self->{mysql_install_db};
		};

		# We should specify --defaults-file option first.
		$cmd .= " --defaults-file='$self->{base_dir}/etc/my.cnf'";

		if ($self->{use_mysqld_initialize}) {
			$cmd .= ' --initialize-insecure';
		} else {
			# `abs_path` resolves nested symlinks and returns canonical absolute path
			my $mysql_base_dir = Cwd::abs_path($self->{mysql_install_db});
			if ($mysql_base_dir =~ s{/(?:bin|extra|scripts)/mysql_install_db$}{}) {
				$cmd .= " --basedir='$mysql_base_dir'";
			}
		}
		$cmd .= ' 2>&1';

		# The MySQL scripts are in Perl, so clear out all current Perl related environment variables before the call.
		local @ENV{ grep {/^PERL/} keys %ENV };

		## no critic (InputOutput::RequireBriefOpen)
		my $output;
		open $fh, '-|', $cmd or die "failed to spawn mysql_install_db:$!";
		while (my $l = <$fh>) { $output .= $l; }
		close $fh or die "*** mysql_install_db failed ***\n% $cmd\n$output\n";
		## use critic (InputOutput::RequireBriefOpen)
	}

	return;
}

sub read_log ($self) {
	open my $logfh, '<', "$self->{base_dir}/tmp/mysqld.log" or die "failed to open file:tmp/mysql.log:$!";
	my $log_contents = do { local $/; <$logfh> };
	close $logfh;
	return $log_contents;
}

sub _find_program ($prog, @subdirs) {
	undef $errstr;
	my $path = _get_path_of($prog);
	return $path if $path;
	for my $mysql (_get_path_of('mysql'), map {"$_/bin/mysql"} @SEARCH_PATHS) {
		if (-x $mysql) {
			for my $subdir (@subdirs) {
				$path = $mysql;
				return $path if ($path =~ s|/bin/mysql$|/$subdir/$prog| && -x $path);
			}
		}
	}
	$errstr = "could not find $prog, please set appropriate PATH";
	return;
}

sub _verbose_help ($self) {
	return $self->{_verbose_help} ||= `$self->{mysqld} --verbose --help 2>/dev/null`;
}

# Detect if mysqld supports `--initialize-insecure` option or not from the output of `mysqld --help --verbose`.
# `mysql_install_db` command is obsoleted for MySQL 5.7.6 or later and `mysqld --initialize-insecure` should be used.
sub _use_mysqld_initialize ($self) {
	return $self->_verbose_help =~ /--initialize-insecure/ms;
}

sub _is_maria ($self) {
	$self->{_is_maria} = $self->_verbose_help =~ /\A.*MariaDB/ unless (exists $self->{_is_maria});
	return $self->{_is_maria};
}

sub _mysql_version ($self) {
	$self->{_mysql_version} = $self->_verbose_help =~ /\A.*Ver ([0-9]+\.[0-9]+\.[0-9]+)/
		unless (exists $self->{_mysql_version});
	return $self->{_mysql_version};
}

sub _mysql_major_version ($self) {
	my $ver = $self->_mysql_version;
	return unless $ver;
	return +(split /\./, $ver)[0];
}

sub _get_path_of ($prog) {
	my $path = `which $prog 2> /dev/null`;
	chomp $path if $path;
	$path = '' unless -x $path;
	return $path;
}

1;
