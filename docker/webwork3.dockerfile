FROM ubuntu:22.04

ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true
ENV DEBCONF_NOWARNINGS yes
ENV HARNESS_PERL_SWITCHES -MDevel::Cover

RUN apt-get update && \
	apt-get install -qy --no-install-recommends --no-install-suggests \
		ca-certificates=20211016 \
		cpanminus=1.7045-1 \
		git=1:2.34.1-1ubuntu1.4 \
		libarray-utils-perl=0.5-2 \
		libc6-dev=2.35-0ubuntu3.1 \
		libcanary-stability-perl=2006-2 \
		libcapture-tiny-perl=0.48-1 \
		libclass-accessor-lite-perl=0.08-1.1 \
		libclone-perl=0.45-1build3 \
		libcommon-sense-perl=3.75-2build1 \
		libcpanel-json-xs-perl=4.27-1build1 \
		libcrypt-ssleay-perl=0.73.06-1build6 \
		libdata-dump-perl=1.25-1 \
		libdatetime-format-strptime-perl=1.7900-1 \
		#libdbd-mysql-perl=4.050-5 \ # if desired to use a full database
		libdbd-sqlite3-perl=1.70-3build1 \
		libdbix-class-inflatecolumn-serializer-perl=0.09-1 \
		libdbix-class-perl=0.082842-3 \
		libdbix-dbschema-perl=0.45-1 \
		libdevel-cover-perl=1.36-2build2 \
		libexception-class-perl=1.45-1 \
		libextutils-config-perl=0.008-2 \
		libextutils-helpers-perl=0.026-1 \
		libextutils-installpaths-perl=0.012-1.1 \
		libfurl-perl=3.14-2 \
		libhttp-parser-xs-perl=0.17-2build1 \
		libimporter-perl=0.026-1 \
		libio-socket-ssl-perl=2.074-2 \
		libjson-perl=4.04000-1 \
		libjson-xs-perl=4.030-1build3 \
		libmodule-build-tiny-perl=0.039-1.1 \
		libmojolicious-perl=9.22+dfsg-1 \
		libmojolicious-plugin-authentication-perl=1.37-1 \
		libnet-ssleay-perl=1.92-1build2 \
		libsql-translator-perl=1.62-1 \
		libssl-dev=3.0.2-0ubuntu1.6 \
		libsub-info-perl=0.015-2 \
		libterm-table-perl=0.015-2 \
		libtest-exception-perl=0.43-1 \
		libtest-harness-perl=3.42-2 \
		libtest2-suite-perl=0.000144-1 \
		libtext-csv-perl=2.01-1 \
		libtry-tiny-perl=0.31-1 \
		libtypes-serialiser-perl=1.01-1 \
		libyaml-libyaml-perl=0.83+ds-1build1 \
		make=4.3-4.1build1 \
		#mariadb-server=1:10.6.7-2ubuntu1.1 \ # if desired to use a full database
		openssl=3.0.2-0ubuntu1.6 && \
	rm -rf /var/lib/apt/lists/* && \
	cpanm --notest \
		DBIx::Class::DynamicSubclass \
		Mojolicious::Plugin::DBIC \
		Mojolicious::Plugin::NotYAMLConfig \
		Test2::MojoX \
		Devel::Cover::Report::Codecov

ENTRYPOINT ["/bin/bash"]
