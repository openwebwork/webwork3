FROM ubuntu:20.04

# the following are needed to make sure the timezone packages don't ask for your timezone.
ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true
ENV HARNESS_PERL_SWITCHES -MDevel::Cover

RUN apt-get update && \
	apt-get install -qy --no-install-recommends --no-install-suggests \
		build-essential=12.8ubuntu1 \
		ca-certificates=20210119~20.04.1 \
		cpanminus=1.7044-1 \
		git=1:2.25.1-1ubuntu3.1 \
		libarray-utils-perl=0.5-1 \
		libclone-perl=0.43-2 \
		libcrypt-ssleay-perl=0.73.06-1build3 \
		libdata-dump-perl=1.23-1 \
		libdatetime-format-strptime-perl=1.7600-1 \
		libdbd-mysql-perl=4.050-3 \
		libdbd-sqlite3-perl=1.64-1build1 \
		libdbix-class-perl=0.082841-1 \
		libdbix-class-inflatecolumn-serializer-perl=0.09-1 \
		libdbix-dbschema-perl=0.45-1 \
		libdevel-cover-perl=1.33-1build1 \
		libexception-class-perl=1.44-1 \
		libjson-perl=4.02000-2 \
		libnet-ssleay-perl=1.88-2ubuntu1 \
		libsql-translator-perl=1.60-1 \
		libssl-dev=1.1.1f-1ubuntu2.5 \
		libtest-exception-perl=0.43-1 \
		libtest-harness-perl=3.42-2 \
		libtext-csv-perl=2.00-1 \
		libtry-tiny-perl=0.30-1 \
		libyaml-libyaml-perl=0.81+repack-1 \
		# mariadb-server=1:10.3.31-0ubuntu0.20.04.1 \ # if desired to use a full database
		openssl=1.1.1f-1ubuntu2.5 && \
	rm -rf /var/lib/apt/lists/* && \
	cpanm --notest \
		DBIx::Class::DynamicSubclass \
		Mojolicious \
		Mojolicious::Plugin::NotYAMLConfig \
		Mojolicious::Plugin::DBIC \
		Mojolicious::Plugin::Authentication \
		Devel::Cover::Report::Codecov

ENTRYPOINT ["/bin/bash"]
