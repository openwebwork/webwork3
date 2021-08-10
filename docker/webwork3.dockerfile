FROM ubuntu:20.04
# the following are needed to make sure the timezone packages don't ask for your timezone.
ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true
ENV HARNESS_PERL_SWITCHES -MDevel::Cover
RUN apt-get update
RUN apt-get install -qy --no-install-recommends --no-install-suggests \
	build-essential=12.8ubuntu1 \
	# mariadb-server=1:10.3.30-0ubuntu0.20.04.1 # if desired to use a full database
	# autoconf=2.69-11.1 \
	# libtool=2.4.6-14 \
	cpanminus=1.7044-1 \
	libssl-dev=1.1.1f-1ubuntu2.4 \
	openssl=1.1.1f-1ubuntu2.4 \
	libtest-harness-perl=3.42-2 \
	libdata-dump-perl=1.23-1 \
	liblist-moreutils-perl=0.416-1build5 \
	libtest-exception-perl=0.43-1 \
	libtry-tiny-perl=0.30-1 \
	libexception-class-perl=1.44-1 \
	libdbix-dbschema-perl=0.45-1 \
	libdbd-sqlite3-perl=1.64-1build1 \
	libtext-csv-perl=2.00-1 \
	libjson-perl=4.02000-2 \
	libdbd-mysql-perl=4.050-3 \
	libnet-ssleay-perl=1.88-2ubuntu1 \
	libcrypt-ssleay-perl=0.73.06-1build3 \
	libdevel-cover-perl=1.33-1build1 \
	git=1:2.25.1-1ubuntu3.1
RUN rm -rf /var/lib/apt/lists/*
RUN cpanm --notest Array::Utils \
	DBIx::Class \
	DBIx::Class::DynamicSubclass \
	DateTime::Format::Strptime \
	Mojolicious \
	Mojolicious::Plugin::NotYAMLConfig \
	Mojolicious::Plugin::DBIC \
	Mojolicious::Plugin::Authentication \
	Devel::Cover::Report::Codecov \
	YAML::XS \
	Clone \
	SQL::Translator
ENTRYPOINT ["/bin/bash"]
